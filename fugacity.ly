\version "2.20.0"
\include "english.ly"
\header {
  title = "Fugacity"
  composer = "Dingus"
}
\score {
  <<
    \override Score.PaperColumn #'keep-inside-line = ##t
    \new Staff {
      \set Staff.instrumentName = \markup{\concat{B \hspace #0.2 \smaller\flat} trumpet}
      \set Staff.shortInstrumentName = #"tpt"
      \set Staff.midiInstrument = #"trumpet"
      \transposition bf
      \transpose bf c' {
        \clef treble
        \time 4/4
        c''2\marcato\f r4 bf'4\ff d''8( gf''8) r2. r1 r1 r2 bf''8\f f'''8\tenuto( c'''4) r1 r1 r1 r1 r2. f'''4\ff r2 ef'''4 r4 r1 r1 r1 r1 r1 r1 r1 r1 r1  \bar "|."
      }
    }
    \new Staff {
      \set Staff.instrumentName = \markup{el. guitar}
      \set Staff.shortInstrumentName = #"eg"
      \set Staff.midiInstrument = #"electric guitar (jazz)"
      \transposition c
      \transpose c c' {
        \clef treble
        \time 4/4
        c''2\tenuto\f bf'4 af'4 e'8 g'8\staccato f'4\accent a'8\tenuto\> f''8( c''4\marcato\!) r4 \ottava #1 af'8 a'8 e'4\tenuto b'4 ef''8 e''8\staccato b'4 gf''4 bf''8 b''8 gf''4 df'''4 f'''8 gf'''8\> df'''4 af'''8 bf''8 d'''8\marcato ef'''8 bf''4 f'''4\accent df'''8 d'''8\marcato a''4 e'''4 c'''8 df'''8 af''4 df''4 gf'4 gf'4 d'8 a'8\accent e'4 af'8\tenuto af'8 df'8 df''8\! gf'4 b8\tenuto b'8 e'4 d'4 g'4 c''4 d''2 \ottava #0 r1 r1 r1 r1 r2 \ottava #1 c''4 bf'4 c''4 d''4\accent c''4 bf'4 af'4\marcato gf'2\accent df''4 bf''2. \ottava #0 r4 r1  \bar "|."
      }
    }
    \new Staff {
      \set Staff.instrumentName = \markup{\concat{B \hspace #0.2 \smaller\flat} tenor sax}
      \set Staff.shortInstrumentName = #"ts"
      \set Staff.midiInstrument = #"tenor sax"
      \tempo Prestissimo 4=200
      \transposition bf,
      \transpose bf, c' {
        \clef treble
        \time 4/4
        c'4\f ef2. r1 r1 r1 r1 r1 r1 r1 r1 r1 r1 r1 r1 r1 r1 r1 r1 r1 r1 r1  \bar "|."
      }
    }
    \new Staff {
      \set Staff.instrumentName = \markup{double bass}
      \set Staff.shortInstrumentName = #"db"
      \set Staff.midiInstrument = #"acoustic bass"
      \transposition c
      \transpose c c' {
        \clef bass
        \time 4/4
        c,4\f^"pizz."\> af,,8( d,8\!) r2 r2 bf,,8 g,8( c4) r4 af,8 c8 f2\tenuto df8 f8 bf8 c8 r4 af,8 c8 f2\> df8\tenuto f8 bf4\! r4 \ottava #1 gf8\mp\< bf8 ef'8\! f8 \ottava #0 r4 a8 a8\staccato r4 r4 a4 r1 r1 r2. a4\p\> g4 g2.\! r1 r1 \ottava #1 d'2\tenuto\> c'4\tenuto g'8\! g8 ef8 ef8 \ottava #0 r4 af,4\ff e,8\< e,8 a,,4\marcato\! r4 g,,8\staccato\mf f,8 r4 r1 r1 r1 r1  \bar "|."
      }
    }
    \new PianoStaff <<
      \set PianoStaff.instrumentName = \markup{pianoforte}
      \set PianoStaff.shortInstrumentName = #"pf"
      \new Staff {
        \set Staff.midiInstrument = #"acoustic grand"
        \transposition c'
        \transpose c' c' {
          \clef treble
          \time 4/4
          c'''4\f ef''4 r4 df''4\mf\< b'4 g'8\accent( g'8 ef'8\accent gf'8) b'4\! r4 g'8\accent\ff\> b'8 e''2\! r1 r1 r1 r1 r1 r1 r2. e''4\tenuto r4 gf''4\marcato\mf r4 gf''4\tenuto\mp e''4\marcato r4 e''4\mf\<( af''8\staccato) af''8\! r2. af''4\staccato r4 af''4\tenuto\mp bf''2\tenuto bf''4 gf''8\marcato gf''8\staccato r2 r4 \ottava #1 e''4\f e''4\accent d''4 e''4\marcato gf''4 e''4\marcato d''4 e''4 gf''4\tenuto af''4 bf''4( f'''4 d''''4 bf'''8 bf'''8\accent\< ef'''4 ef'''4 b''8\marcato) af'''8\tenuto f''''4\! bf'''4 \ottava #0  \bar "|."
        }
      }
      \new Staff {
        \set Staff.midiInstrument = #"acoustic grand"
        \transposition c'
        \transpose c' c' {
          \clef bass
          \time 4/4
          c,2\f d,2 bf,,8 gf,8 df4 a,8 bf,8 f,4\< bf,,4 bf,,4\! bf,,4 r4 gf,,8\ff df,8 ef,4\< af,4 af,4\tenuto\! r1 r1 r1 r1 r1 r1 r2 ef2\mp\> f4 c'4\! e'8 e'8\accent r4 a4 f8 f8\< bf,4\marcato c4\!( d1) r1 r4 d2 e4\staccato r1 r1 r1 r1  \bar "|."
        }
      }
    >>
  >>
  \midi{}
  \layout{}
}