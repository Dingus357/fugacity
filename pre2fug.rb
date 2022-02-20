#!/usr/bin/env ruby

# This script metaprograms a LilyPond file <http://lilypond.org> that typesets the musical score for a Fugue program <https://esolangs.org/wiki/Fugue>.
# The Fugue source code is itself generated from code written in its sister language, Prelude <https://esolangs.org/wiki/Prelude>.
# LilyPond absolute notation is used for all pitches.

# Output file
LY_FILE = 'fugacity.ly'

# The Prelude source code to convert
prelude = <<PRELUDE.lines
  v4             7-                   +  v
 vv3v8- 1-(1-(1-(1-(1-(1-(1-))#7-0))))v++^                   vv^^vvvv (!
?
6    9+ 4+ 4+ 4+ 4+ 4+ 0  #           #v#          ( v(0 )0) v
? vv03+ 4+                            # ^ #v #0   # #^ #0   v#v^^vv^^^^(!0)#9!)
 ^ 8(1-)## 7^+#                          ( ^(0 )0)^^        # ^
PRELUDE
# Pad lines to same length with no-ops and pad out last bar to a multiple of 4 crotchets if necessary.
llen = prelude.max_by { |l| l.size }.chomp.size + 1 # the +1 accounts for the (arbitrary) first note added below
llen += (llen % 4 == 0 ? 0 : 4 - llen % 4)
# Add # (unison) to start of each voice to insert first note.
PRELUDE = prelude.map{ |l| ('#' + l.chomp).ljust(llen) }.join("\n")

# Map Prelude instructions to appropriate semitone intervals. Push commands are handled separately later.
PRELUDE_CMDS = {
  '#' =>  0,
  '^' =>  2,
  'v' => -2,
  '+' =>  5,
  '-' => -5,
  '(' =>  7,
  ')' => -7,
  '!' =>  9,
  '?' => -9,
}

# Scientific pitches C0-B8
SCALE = [",,,", ",,", ",", "", "'", "''", "'''", "''''", "'''''"].flat_map { |i| %w[c df d ef e f gf g af a bf b].map { |n| "#{n}#{i}" } } 

# Match a LilyPond absolute pitch
PITCH_MATCHER = /\b[a-g][fs]?[,']*/

# Match a 4/4 bar containing only crotchets and/or quavers
BAR_MATCHER = /#{[[4]*4, *[4,4,4,8,8].permutation, *[4,4,8,8,8,8].permutation, *[4,8,8,8,8,8,8].permutation, [8]*8].uniq.map { |b| b.map { |n|"\\S*#{n}\\S* " }.join }.join('|') }/

####################################################################################################
# ARTISTIC SETTINGS

# Probabilities for random artistic embellishments
P_MERGE = 0.5
P_DYNAMIC = 0.5
P_ACCENT = 0.25
P_SLUR = 0.5
P_CRESC = 0.5

# Dynamics are chosen at random from this array
#DYNAMICS = %w[pp p mp mf f ff]
DYNAMICS = ['pp'] + ['p']*2 + ['mp']*3 + ['mf']*4 + ['f']*5 + ['ff']*6 # favour louder dynamics

# Instruments
# transposition is the note heard (in LilyPond absolute notation) when written c' (C4/middle C) is played.
# start_pitch is the first note (concert pitch) to be played.
Voice = Struct.new(:midi, :long_name, :short_name, :transposition, :clef, :start_pitch, :sounding_range)
voices = [
  Voice.new('trumpet',                '\concat{B \hspace #0.2 \smaller\flat} trumpet',    'tpt',  "bf",   'treble', "c''",  %w[e    bf''']),
  Voice.new('electric guitar (jazz)', 'el. guitar',                                       'eg',   "c",    'treble', "c''",  %w[e    d'''']),
  Voice.new('tenor sax',              '\concat{B \hspace #0.2 \smaller\flat} tenor sax',  'ts',   "bf,",  'treble', "c'",   %w[af,  ef'']),
  Voice.new('acoustic bass',          'double bass',                                      'db',   "c",    'bass',   "c,",   %w[e,,  g']),
  Voice.new('acoustic grand',         'pianoforte',                                       'pf',   "c'",   'treble', "c'''", %w[a,,, c''''']),
  Voice.new('acoustic grand',         'pianoforte',                                       'pf',   "c'",   'bass',   "c,",   %w[a,,, c''''']),
]

####################################################################################################
# MAIN PROGRAM

# Initialise the score
score = %q(\version "2.20.0"
  \include "english.ly"
  \header {
  title = "Fugacity"
  composer = "Dingus"
  }
  \score {
  <<
  \override Score.PaperColumn #'keep-inside-line = ##t
)

# Loop over voices
PRELUDE.lines do |l|
  voice = voices.shift
  if voice.short_name == 'pf' && !voices.empty?
    score << %(\\new PianoStaff <<
      \\set PianoStaff.instrumentName = \\markup{#{voice.long_name}}
      \\set PianoStaff.shortInstrumentName = #"#{voice.short_name}"
    )
  end
  score << "\\new Staff {\n"
  unless voice.short_name == 'pf'
    score << %(\\set Staff.instrumentName = \\markup{#{voice.long_name}}
      \\set Staff.shortInstrumentName = #"#{voice.short_name}"
    )
  end
  score << %(\\set Staff.midiInstrument = #"#{voice.midi}"
    \\tempo Prestissimo 4=200
    \\transposition #{voice.transposition}
    \\transpose #{voice.transposition} c' {
    \\clef #{voice.clef}
    \\time 4/4
  )

  # Determine basic pitches and rhythms
  basic_part = ''
  catch :success do
    # Jumps of 10 semitones or more (which are no-ops) are automatically added to try to keep the music within the instrument's playing range.
    # range_limiter controls how frequently this feature is applied. Smaller values favour more jump insertions.
    # We start with the largest sensible value and gradually decrease it until the entire part is playable.
    # If range_limiter hits 0, the chosen start_pitch is probably too close to one of the extremes of the instrument's range.
    ((SCALE.index(voice.sounding_range.last) - SCALE.index(voice.sounding_range.first))/2).downto(0) do |range_limiter|
      catch :unplayable do
        basic_part = ''
        pitch_index = SCALE.index(voice.start_pitch)
        range = [pitch_index, pitch_index]
        # Convert Prelude instructions to intervals.
        # Most instructions except push commands (see below) become crotchets.
        # The exception is when range-limiting jumps are added, in which case the instruction and the jump become a pair of quavers.
        l.chomp.chars.map do |c|
          deltas = case c
            when Regexp.union(PRELUDE_CMDS.keys)
              cmd = PRELUDE_CMDS[c]
              if range.max - range.min > range_limiter # introduce a jump of 10 semitones or more to counteract instructions that extend the range too much
                if pitch_index + cmd > range.max
                  [cmd, [-10, -11, -12].sample]
                elsif pitch_index + cmd < range.min
                  [cmd, [10, 11, 12].sample]
                else
                  cmd
                end
              else
                cmd
              end
            # Push commands are converted to a pair of quavers.
            # The first is an ascending or descending third (chosen randomly, except when range_limiter comes into play).
            # The second is the number to be pushed (as a number of semitones).
            when /(\d)/
              digit = $1.to_i
              thirds = if range.max - range.min > range_limiter
                [(pitch_index + digit - 4 < range.min ? 4 : -4), (pitch_index + digit + 4 > range.max ? -4 : 4)]
              else
                [-4, 4]
              end
              [thirds.sample, digit]
          end
          unless deltas # handle no-ops, which become crotchet rests
            basic_part << 'r4 '
            next
          end
          deltas = [*deltas]
          deltas.each do |delta|
            pitch_index += delta
            unless (SCALE.index(voice.sounding_range.first)..SCALE.index(voice.sounding_range.last)) === pitch_index
              raise "Attempt to set range_limiter below 0 for voice #{voice.short_name}. Try changing the start_pitch for this voice." if range_limiter == 0
              throw :unplayable # range_limiter too loose; tighten it and try again
            end
            range = (range + [pitch_index]).minmax
            basic_part << "#{SCALE[pitch_index]}#{deltas.size < 2 ? 4 : 8} "
          end
        end
        throw :success
      end
    end
  end

  # Now embellish the basic score
  part = ''
  # Consolidate notes and rests
  basic_part.scan(/#{BAR_MATCHER}|.+/) do |bar|
    raise "incomplete bar in voice #{voice.short_name}: #{bar} #{bar.bytes}" unless bar =~ BAR_MATCHER
    bar.sub!(/([^r ]\S*)4 r4 r4 r4/){"#{$1}1"} if rand < P_MERGE # semibreve
    bar.sub!(/([^r ]\S*)4 r4 r4/){"#{$1}2."} if rand < P_MERGE # dotted minim
    bar.gsub!(/([^r ]\S*)4 r4/){"#{$1}2"} if rand < P_MERGE # minim
    bar.sub!(/r4 r4 r4 r4/, 'r1') # semibreve rest
    bar.sub!(/r4 r4 r4/, 'r2.') # dotted minim rest
    bar.sub!(/(^r4 r4 |r4 r4 $)/, 'r2 ') # minim rest
    part << bar
  end

  # Add annotations to notes
  first_run = true
  dynamic = 'f'
  part.gsub!(/([^r ]\S*\d\.? )+/) do |run|
    notes = run.scan(/\S*\d\.?/)
    length = notes.size
    notes.map! do |n|
      # Accents
      accents = %w[accent marcato tenuto]
      accents << 'staccato' if n =~ /[48]/ # staccato for crotchets and quavers only
      n << "\\#{accents.sample}" if rand < P_ACCENT
      n
    end
    # Dynamics
    if first_run # set consistent dynamic for all voices at beginning of piece
      notes[0] << "\\#{dynamic}#{'^"pizz."' if voice.short_name == 'db'}"
      first_run = false
    elsif rand < P_DYNAMIC
      dynamic = (DYNAMICS - [dynamic]).sample # avoid setting the same dynamic twice in a row
      notes[0] << "\\#{dynamic}"
    end
    # Hairpins start and end at randomly selected points
    if length > 2 && rand < P_CRESC
      start = [*0..length-3].sample
      stop = [*start+2..length-1].sample
      notes[start] << "\\#{%w[< >].sample}"
      notes[stop] << '\!'
    end
    # Slurs start and end at randomly selected points
    if length > 1 && rand < P_SLUR
      start = [*0..length-2].sample
      stop = [*start+1..length-1].sample
      start_note = notes[start][PITCH_MATCHER]
      stop_note = notes[stop][PITCH_MATCHER]
      if notes[start..stop].map { |n| n[PITCH_MATCHER] }.uniq.size > 1 # don't slur over unison notes (looks like a tie)
        notes[start] << '('
        notes[stop] << ')'
      end
    end
    # Use 8va marks for runs of notes that would otherwise have more than 4 leger lines
    if (voice.clef == 'treble' && notes.any? { |n| SCALE.index(n[PITCH_MATCHER]) > SCALE.index("g''#{"'" unless voice.transposition == 'c'}") }) ||
       (voice.clef == 'bass'   && notes.any? { |n| SCALE.index(n[PITCH_MATCHER]) > SCALE.index("b#{"'" unless voice.transposition == 'c'}") })
      notes[0] = "\\ottava #1 #{notes[0]}"
      notes[-1] = "#{notes[-1]} \\ottava #0"
    end
    notes.join(' ')+' '
  end

  score << %(#{part} \\bar "|."
    }
    }
  )
end

# Finalise the score
score << %q(>>
  >>
  \midi{}
  \layout{}
  }
)

# Fix indentation
indent = 0
lines = score.lines
lines.map! do |line|
  indent -= 1 if line =~ /^\s*(}|>>)/
  line = ' '*indent*2 + line.strip
  indent += 1 if line =~ /{[^}]*$|<<[^>]*$/
  line
end
score = lines.join("\n")

# Run LilyPond
File.write(LY_FILE, score)
`lilypond #{LY_FILE}`
