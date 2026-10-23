;; ============================================================
;; DRAWING INDEX GENERATOR
;; AutoCAD LT 2026
;;
;; Command:
;;   BUILDINDEX
;;
;; Finds MTEXT on TITLE-INDEX inside the drawing grid,
;; determines its grid position from its insertion point,
;; and generates a numbered drawing index.
;;
;; ============================================================


;; ============================================================
;; USER PARAMETERS
;; ============================================================


;; ------------------------------------------------------------
;; TITLE OBJECTS
;; ------------------------------------------------------------

;; Layer containing drawing-title MTEXT.

(setq DI-TITLE-LAYER "TITLE-INDEX")


;; ------------------------------------------------------------
;; GRID REFERENCE
;; ------------------------------------------------------------

;; TOP-LEFT CORNER OF RECTANGLE 1-00.

(setq DI-GRID-X 18.0)
(setq DI-GRID-Y 10.0)


;; ------------------------------------------------------------
;; ACTUAL RECTANGLE SIZE
;; ------------------------------------------------------------

(setq DI-RECT-WIDTH 14.137)
(setq DI-RECT-HEIGHT 10.0)


;; ------------------------------------------------------------
;; GRID PITCH
;; ------------------------------------------------------------

;; Horizontal distance from the left edge of one
;; rectangle to the left edge of the next.

(setq DI-PITCH-X 16.0)


;; Vertical distance from the top edge of one
;; rectangle to the top edge of the next.

(setq DI-PITCH-Y 12.0)


;; ------------------------------------------------------------
;; GRID LIMITS
;; ------------------------------------------------------------

;; Maximum number of rows and columns in the template.

(setq DI-MAX-ROWS 20)
(setq DI-MAX-COLS 50)


;; ------------------------------------------------------------
;; TITLE POSITION
;; ------------------------------------------------------------

;; Title insertion point relative to the
;; TOP-LEFT corner of each rectangle.

(setq DI-TITLE-OFFSET-X 7.0685)
(setq DI-TITLE-OFFSET-Y -0.075)


;; ------------------------------------------------------------
;; TITLE POSITION TOLERANCE
;; ------------------------------------------------------------

;; Maximum distance an MTEXT insertion point may differ
;; from the calculated title position.

(setq DI-TITLE-TOLERANCE 0.10)


;; ------------------------------------------------------------
;; SELECTION BOX PADDING
;; ------------------------------------------------------------

;; Small additional margin around the calculated
;; outer grid boundary.

(setq DI-SEARCH-PADDING 0.10)


;; ------------------------------------------------------------
;; FINAL INDEX OUTPUT
;; ------------------------------------------------------------

;; Insertion point of generated index.

(setq DI-INDEX-X 1.35)
(setq DI-INDEX-Y 5.5)


;; Text height of generated index.

(setq DI-INDEX-TEXT-HEIGHT 0.1)


;; AutoCAD text style.
;; Must already exist in the drawing.

(setq DI-INDEX-TEXT-STYLE "ROMAND")


;; Layer for generated index.

(setq DI-INDEX-LAYER "DRAWING-INDEX")


;; Heading.

(setq DI-INDEX-HEADING "")


;; ============================================================
;; GET GRID CELL
;; ============================================================

(defun DI-GET-CELL
  (x y
   /
   title-origin-x
   title-origin-y
   col
   row
   expected-x
   expected-y
   dx
   dy
  )

  ;; ----------------------------------------------------------
  ;; Calculate insertion point of title in cell 1-00.
  ;; ----------------------------------------------------------

  (setq title-origin-x
    (+
      DI-GRID-X
      DI-TITLE-OFFSET-X
    )
  )

  (setq title-origin-y
    (+
      DI-GRID-Y
      DI-TITLE-OFFSET-Y
    )
  )


  ;; ----------------------------------------------------------
  ;; Determine column.
  ;; ----------------------------------------------------------

  (setq col
    (fix
      (+
        0.5
        (/
          (- x title-origin-x)
          DI-PITCH-X
        )
      )
    )
  )


  ;; ----------------------------------------------------------
  ;; Determine row.
  ;;
  ;; Drawing Y increases upward, while our rows increase
  ;; downward, so the subtraction is intentional.
  ;; ----------------------------------------------------------

  (setq row
    (fix
      (+
        0.5
        (/
          (- title-origin-y y)
          DI-PITCH-Y
        )
      )
    )
  )


  ;; ----------------------------------------------------------
  ;; Calculate exact expected title position.
  ;; ----------------------------------------------------------

  (setq expected-x
    (+
      title-origin-x
      (* col DI-PITCH-X)
    )
  )

  (setq expected-y
    (-
      title-origin-y
      (* row DI-PITCH-Y)
    )
  )


  ;; ----------------------------------------------------------
  ;; Calculate positional error.
  ;; ----------------------------------------------------------

  (setq dx
    (abs
      (- x expected-x)
    )
  )

  (setq dy
    (abs
      (- y expected-y)
    )
  )


  ;; ----------------------------------------------------------
  ;; Validate.
  ;; ----------------------------------------------------------

  (if
    (and

      (<= dx DI-TITLE-TOLERANCE)

      (<= dy DI-TITLE-TOLERANCE)

      (>= row 0)

      (>= col 0)

      (< row DI-MAX-ROWS)

      (< col DI-MAX-COLS)

    )

    (list row col)

    nil
  )
)


;; ============================================================
;; GET MTEXT CONTENT
;; ============================================================

(defun DI-GET-TEXT
  (ent
   /
   data
   txt
   item
  )

  (setq data
    (entget ent)
  )

  (setq txt "")


  ;; MTEXT can split long strings between group 3
  ;; and group 1 records.

  (foreach item data

    (cond

      ((= (car item) 3)

        (setq txt
          (strcat
            txt
            (cdr item)
          )
        )
      )

      ((= (car item) 1)

        (setq txt
          (strcat
            txt
            (cdr item)
          )
        )
      )

    )
  )

  txt
)


;; ============================================================
;; CLEAN MTEXT
;; ============================================================

;; ============================================================
;; CLEAN / UNFORMAT MTEXT
;; ============================================================

(defun DI-CLEAN-TEXT
  (txt
   /
   pos
   end
   code
  )

  ;; ----------------------------------------------------------
  ;; Convert paragraph breaks to spaces.
  ;; ----------------------------------------------------------

  (while
    (vl-string-search "\\P" txt)

    (setq txt
      (vl-string-subst
        " "
        "\\P"
        txt
      )
    )
  )


  ;; ----------------------------------------------------------
  ;; Remove simple on/off formatting codes.
  ;;
  ;; \L = underline on
  ;; \l = underline off
  ;; \O = overline on
  ;; \o = overline off
  ;; \K = strikethrough on
  ;; \k = strikethrough off
  ;; ----------------------------------------------------------

  (foreach code
    '("\\L" "\\l" "\\O" "\\o" "\\K" "\\k")

    (while
      (vl-string-search code txt)

      (setq txt
        (vl-string-subst
          ""
          code
          txt
        )
      )
    )
  )


  ;; ----------------------------------------------------------
  ;; Remove formatting commands that terminate with ";"
  ;;
  ;; Examples:
  ;;
  ;; \C1;
  ;; \C256;
  ;; \H0.75x;
  ;; \W0.8;
  ;; \T0.9;
  ;; \Q15;
  ;; \A1;
  ;;
  ;; These commands affect formatting but contain no
  ;; meaningful title text.
  ;; ----------------------------------------------------------

  (foreach code
    '("\\C" "\\H" "\\W" "\\T" "\\Q" "\\A")

    (while

      (setq pos
        (vl-string-search code txt)
      )

      (setq end
        (vl-string-search
          ";"
          txt
          (+ pos 2)
        )
      )

      (if end

        (setq txt

          (strcat

            ;; Text before the formatting command.

            (substr
              txt
              1
              pos
            )

            ;; Text after the semicolon.

            (substr
              txt
              (+ end 2)
            )

          )
        )

        ;; If there is no terminating semicolon,
        ;; remove the formatting command itself.

        (setq txt
          (vl-string-subst
            ""
            code
            txt
          )
        )
      )
    )
  )


  ;; ----------------------------------------------------------
  ;; Remove font formatting.
  ;;
  ;; Example:
  ;;
  ;; \FArial|b1|i0;Some Title
  ;;
  ;; becomes:
  ;;
  ;; Some Title
  ;; ----------------------------------------------------------

  (while

    (setq pos
      (vl-string-search "\\F" txt)
    )

    (setq end
      (vl-string-search
        ";"
        txt
        (+ pos 2)
      )
    )

    (if end

      (setq txt

        (strcat

          (substr
            txt
            1
            pos
          )

          (substr
            txt
            (+ end 2)
          )

        )
      )

      (setq txt
        (vl-string-subst
          ""
          "\\F"
          txt
        )
      )
    )
  )


  ;; ----------------------------------------------------------
  ;; Remove stacked fraction formatting.
  ;;
  ;; MTEXT can contain:
  ;;
  ;; \S1/2;
  ;;
  ;; We keep the actual fraction contents and remove
  ;; the \S formatting wrapper.
  ;; ----------------------------------------------------------

  (while

    (setq pos
      (vl-string-search "\\S" txt)
    )

    (setq end
      (vl-string-search
        ";"
        txt
        (+ pos 2)
      )
    )

    (if end

      (progn

        (setq txt

          (strcat

            ;; Text before \S.

            (substr
              txt
              1
              pos
            )

            ;; Contents between \S and ;.

            (substr
              txt
              (+ pos 3)
              (-
                end
                pos
                2
              )
            )

            ;; Text after ;.

            (substr
              txt
              (+ end 2)
            )

          )
        )
      )

      (setq txt
        (vl-string-subst
          ""
          "\\S"
          txt
        )
      )
    )
  )


  ;; ----------------------------------------------------------
  ;; Remove braces used by MTEXT formatting.
  ;; ----------------------------------------------------------

  (while
    (vl-string-search "{" txt)

    (setq txt
      (vl-string-subst
        ""
        "{"
        txt
      )
    )
  )

  (while
    (vl-string-search "}" txt)

    (setq txt
      (vl-string-subst
        ""
        "}"
        txt
      )
    )
  )


  ;; ----------------------------------------------------------
  ;; Return completely unformatted text.
  ;; ----------------------------------------------------------

  txt
)


;; ============================================================
;; CREATE INDEX LAYER
;; ============================================================

(defun DI-MAKE-LAYER ()

  (if

    (not
      (tblsearch
        "LAYER"
        DI-INDEX-LAYER
      )
    )

    (entmake
      (list

        '(0 . "LAYER")

        '(100 . "AcDbSymbolTableRecord")

        '(100 . "AcDbLayerTableRecord")

        (cons
          2
          DI-INDEX-LAYER
        )

        '(70 . 0)

        '(62 . 7)

      )
    )
  )
)


;; ============================================================
;; DELETE PREVIOUS INDEX
;; ============================================================

(defun DI-DELETE-OLD
  (/ ss i)

  (setq ss

    (ssget
      "_X"

      (list

        '(0 . "MTEXT")

        (cons
          8
          DI-INDEX-LAYER
        )

      )
    )
  )


  (if ss

    (progn

      (setq i 0)

      (while

        (<
          i
          (sslength ss)
        )

        (entdel
          (ssname ss i)
        )

        (setq i
          (1+ i)
        )
      )
    )
  )
)


;; ============================================================
;; CREATE INDEX MTEXT
;; ============================================================

(defun DI-CREATE-INDEX
  (txt
   /
   ent
   chunks
   chunk
   maxlen
  )

  ;; MTEXT DXF group 1 has a maximum string length.
  ;; Store long text in group 3 chunks.

  (setq maxlen 250)

  (setq chunks nil)

  ;; Split text into chunks.

  (while
    (> (strlen txt) maxlen)

    (setq chunk
      (substr
        txt
        1
        maxlen
      )
    )

    (setq chunks
      (cons
        chunk
        chunks
      )
    )

    (setq txt
      (substr
        txt
        (1+ maxlen)
      )
    )
  )

  ;; Remaining text is the final group 1 string.

  (setq chunks
    (reverse chunks)
  )


  ;; Create the MTEXT entity.

  (setq ent

    (entmakex

      (append

        (list

          '(0 . "MTEXT")

          '(100 . "AcDbEntity")

          ;; Layer

          (cons
            8
            DI-INDEX-LAYER
          )

          '(100 . "AcDbMText")

          ;; Insertion point

          (cons
            10
            (list
              DI-INDEX-X
              DI-INDEX-Y
              0.0
            )
          )

          ;; Text style

          (cons
            7
            DI-INDEX-TEXT-STYLE
          )

          ;; Text height

          (cons
            40
            DI-INDEX-TEXT-HEIGHT
          )

          ;; Width = 0 means no fixed width.

          '(41 . 0.0)

          ;; Rotation

          '(50 . 0.0)

        )

        ;; Group 3 chunks.

        (mapcar
          '(lambda (s)
             (cons 3 s)
           )
          chunks
        )

        ;; Final group 1.

        (list
          (cons
            1
            txt
          )

          ;; Top-left attachment.

          '(71 . 1)

          ;; Left-to-right drawing direction.

          '(72 . 1)

        )

      )
    )
  )

  ent
)

;; ============================================================
;; SORT TITLES
;; ============================================================

(defun DI-SORT-TITLES
  (lst
   /
   result
   item
   before
   inserted
  )

  (setq result nil)


  (foreach item lst

    ;; Empty result.

    (if

      (null result)

      (setq result
        (list item)
      )


      (progn

        (setq before nil)
        (setq inserted nil)


        ;; Find proper insertion point.

        (while

          (and
            result
            (not inserted)
          )

          (if

            (or

              ;; Earlier row.

              (<
                (car item)
                (car (car result))
              )


              ;; Same row, earlier column.

              (and

                (=
                  (car item)
                  (car (car result))
                )

                (<
                  (cadr item)
                  (cadr (car result))
                )

              )

            )

            (progn

              (setq result
                (cons
                  item
                  result
                )
              )

              (setq inserted T)
            )


            (progn

              (setq before
                (cons
                  (car result)
                  before
                )
              )

              (setq result
                (cdr result)
              )
            )
          )
        )


        ;; Reassemble list.

        (if

          (not inserted)

          (setq result

            (append

              (reverse before)

              (list item)

              result

            )
          )


          (setq result

            (append

              (reverse before)

              result

            )
          )
        )
      )
    )
  )

  result
)


;; ============================================================
;; BUILD NUMBERED LIST
;; ============================================================

(defun DI-BUILD-LIST
  (entries
   /
   output
   count
   item
   tab
  )

  ;; ASCII character 9 = real tab character.

  (setq tab
    (chr 9)
  )


  ;; Heading.

  (setq output
    (strcat
      ;;DI-INDEX-HEADING
      ;;"\\P"
    )
  )


  (setq count 0)


  ;; Add each drawing.

  (foreach item entries

    (setq count
      (1+ count)
    )


    (setq output

      (strcat

        output

        ;; Number.

        (itoa count)

        "."

        ;; REAL TAB.

        tab

        ;; Title.

        (caddr item)

        ;; New paragraph.

        "\\P"

      )
    )
  )


  output
)


;; ============================================================
;; MAIN COMMAND
;; ============================================================

(defun c:BUILDINDEX
  (
    /
    p1
    p2
    ss
    i
    ent
    data
    ip
    cell
    row
    col
    text
    entries
    output
    count

    ;; Grid calculations.

    gap-x
    gap-y
    grid-width
    grid-height
    grid-end-x
    grid-end-y
  )

  (c:BUILDTITLEARRAY)
  (princ
    "\nBuilding drawing index..."
  )


  ;; ==========================================================
  ;; CALCULATE GRID GAPS
  ;; ==========================================================

  ;; Pitch is authoritative.
  ;;
  ;; Gap = pitch - rectangle size.

  (setq gap-x
    (-
      DI-PITCH-X
      DI-RECT-WIDTH
    )
  )


  (setq gap-y
    (-
      DI-PITCH-Y
      DI-RECT-HEIGHT
    )
  )


  ;; ==========================================================
  ;; CALCULATE TOTAL GRID SIZE
  ;; ==========================================================

  ;; Total width:
  ;;
  ;;   rectangles + gaps
  ;;
  ;; There is one fewer gap than rectangles.

  (setq grid-width

    (+

      (*

        DI-MAX-COLS
        DI-RECT-WIDTH

      )

      (*

        (1- DI-MAX-COLS)
        gap-x

      )

    )
  )


  ;; Total height.

  (setq grid-height

    (+

      (*

        DI-MAX-ROWS
        DI-RECT-HEIGHT

      )

      (*

        (1- DI-MAX-ROWS)
        gap-y

      )

    )
  )


  ;; ==========================================================
  ;; CALCULATE OUTER GRID BOUNDS
  ;; ==========================================================

  ;; Top-left of grid is DI-GRID-X / DI-GRID-Y.

  (setq grid-end-x
    (+
      DI-GRID-X
      grid-width
    )
  )


  (setq grid-end-y
    (-
      DI-GRID-Y
      grid-height
    )
  )


  ;; ==========================================================
  ;; SELECTION WINDOW
  ;; ==========================================================

  ;; Lower-left corner.

  (setq p1

    (list

      (-

        DI-GRID-X
        DI-SEARCH-PADDING

      )

      (-

        grid-end-y
        DI-SEARCH-PADDING

      )

    )
  )


  ;; Upper-right corner.

  (setq p2

    (list

      (+

        grid-end-x
        DI-SEARCH-PADDING

      )

      (+

        DI-GRID-Y
        DI-SEARCH-PADDING

      )

    )
  )


;; ==========================================================
;; DATABASE SEARCH
;; ==========================================================

;; Search the drawing database directly.
;;
;; This is NOT a graphical selection and therefore does not
;; depend on what portion of Model Space is currently visible.
;;
;; AutoCAD first filters to:
;;
;;     MTEXT
;;     TITLE-INDEX layer
;;
;; Then the code below checks whether each object's insertion
;; point falls inside the calculated grid.

(setq ss

  (ssget

    "_X"

    (list

      '(0 . "MTEXT")

      (cons
        8
        DI-TITLE-LAYER
      )

    )
  )
)

  ;; ==========================================================
  ;; PROCESS FOUND MTEXT
  ;; ==========================================================

  (if ss

    (progn

      (setq i 0)


      (while

        (<
          i
          (sslength ss)
        )


        (setq ent
          (ssname ss i)
        )


        (setq data
          (entget ent)
        )


        ;; MTEXT insertion point.

        (setq ip
          (cdr
            (assoc 10 data)
          )
        )


        (if ip

          (progn

            ;; Determine grid position.

            (setq cell

              (DI-GET-CELL

                (car ip)
                (cadr ip)

              )
            )


            (if cell

              (progn

                (setq row
                  (car cell)
                )


                (setq col
                  (cadr cell)
                )


                ;; Get title.

                (setq text

                  (DI-CLEAN-TEXT

                    (DI-GET-TEXT ent)

                  )
                )


                ;; Ignore blank titles.

                (if

                  (> (strlen text) 0)

                  (setq entries

                    (cons

                      (list

                        row
                        col
                        text

                      )

                      entries
                    )
                  )
                )
              )
            )
          )
        )


        (setq i
          (1+ i)
        )
      )
    )
  )


  ;; ==========================================================
  ;; SORT
  ;; ==========================================================

  (setq entries

    (DI-SORT-TITLES entries)

  )


  ;; ==========================================================
  ;; BUILD INDEX
  ;; ==========================================================

  (setq count
    (length entries)
  )


  (if

    (> count 0)

    (progn

      ;; Generate MTEXT.

      (setq output

        (DI-BUILD-LIST
          entries
        )
      )


      ;; Ensure output layer exists.

      (DI-MAKE-LAYER)


      ;; Remove previous generated index.

      (DI-DELETE-OLD)


      ;; Create new index.

      (DI-CREATE-INDEX output)


      (princ

        (strcat

          "\nDrawing index updated: "

          (itoa count)

          " titles found."

        )
      )
    )


    (princ

      "\nNo valid titles found. Existing index was left unchanged."

    )
  )


  (princ)
)


;; ============================================================
;; LOAD MESSAGE
;; ============================================================

(princ
  "\nDrawing Index loaded. Type BUILDINDEX to run."
)

(princ)

;; ============================================================
;; TITLE ARRAY
;; ============================================================
;;
;; Creates individual MTEXT objects containing the drawing
;; titles only, without the numbered prefixes used by BUILDINDEX.
;;
;; Command:
;;   BUILDTITLEARRAY
;;
;; This section is completely independent of BUILDINDEX.
;; It does not modify TITLE-INDEX objects.
;;
;; ============================================================


;; ============================================================
;; TITLE ARRAY PARAMETERS
;; ============================================================

;; First title insertion point.

(setq DI-TITLE-ARRAY-X 0.875)
(setq DI-TITLE-ARRAY-Y -1.25)


;; Vertical spacing between titles.

(setq DI-TITLE-ARRAY-SPACING 0.5)


;; Width of each MTEXT object.

(setq DI-TITLE-ARRAY-WIDTH 1.75)


;; Text height.

(setq DI-TITLE-ARRAY-HEIGHT 0.07)


;; Text style.

(setq DI-TITLE-ARRAY-STYLE "ROMAND")


;; Layer for generated title array.

(setq DI-TITLE-ARRAY-LAYER "TITLE-ARRAY")


;; ============================================================
;; CREATE TITLE ARRAY LAYER
;; ============================================================

(defun DI-MAKE-TITLE-ARRAY-LAYER ()

  (if

    (not
      (tblsearch
        "LAYER"
        DI-TITLE-ARRAY-LAYER
      )
    )

    (entmake
      (list

        '(0 . "LAYER")

        '(100 . "AcDbSymbolTableRecord")

        '(100 . "AcDbLayerTableRecord")

        (cons
          2
          DI-TITLE-ARRAY-LAYER
        )

        '(70 . 0)

        '(62 . 7)

      )
    )
  )
)


;; ============================================================
;; DELETE PREVIOUS TITLE ARRAY
;; ============================================================

(defun DI-DELETE-TITLE-ARRAY
  (/ ss i)

  ;; Only delete MTEXT on TITLE-ARRAY.
  ;;
  ;; TITLE-INDEX is completely untouched.

  (setq ss

    (ssget
      "_X"

      (list

        '(0 . "MTEXT")

        (cons
          8
          DI-TITLE-ARRAY-LAYER
        )

      )
    )
  )


  (if ss

    (progn

      (setq i 0)

      (while

        (<
          i
          (sslength ss)
        )

        (entdel
          (ssname ss i)
        )

        (setq i
          (1+ i)
        )
      )
    )
  )
)


;; ============================================================
;; CREATE ONE TITLE ARRAY MTEXT
;; ============================================================

(defun DI-CREATE-TITLE-ARRAY-MTEXT
  (txt x y
   /
   ent
  )

  (setq ent

    (entmakex

      (list

        '(0 . "MTEXT")

        '(100 . "AcDbEntity")


        ;; Layer.

        (cons
          8
          DI-TITLE-ARRAY-LAYER
        )


        '(100 . "AcDbMText")


        ;; Insertion point.
        ;;
        ;; Because attachment point is Middle Center,
        ;; this point is the center of the MTEXT box.

        (cons
          10
          (list
            x
            y
            0.0
          )
        )


        ;; Text style.

        (cons
          7
          DI-TITLE-ARRAY-STYLE
        )


        ;; Text height.

        (cons
          40
          DI-TITLE-ARRAY-HEIGHT
        )


        ;; MTEXT width.

        (cons
          41
          DI-TITLE-ARRAY-WIDTH
        )


        ;; Rotation.

        '(50 . 0.0)


        ;; Title text.

        (cons
          1
          txt
        )


        ;; Middle Center attachment.

        '(71 . 5)


        ;; Left-to-right drawing direction.

        '(72 . 1)

      )
    )
  )

  ent
)


;; ============================================================
;; BUILD TITLE ARRAY
;; ============================================================

(defun DI-BUILD-TITLE-ARRAY
  (entries
   /
   y
   item
  )

  ;; Start at the specified first insertion point.

  (setq y
    DI-TITLE-ARRAY-Y
  )


  ;; Create one MTEXT object per drawing title.

  (foreach item entries

    (DI-CREATE-TITLE-ARRAY-MTEXT

      ;; Title only.
      ;;
      ;; entries are:
      ;;   (row col title)

      (caddr item)

      ;; X position.

      DI-TITLE-ARRAY-X

      ;; Y position.

      y

    )


    ;; Move downward for next title.

    (setq y
      (-
        y
        DI-TITLE-ARRAY-SPACING
      )
    )
  )
)


;; ============================================================
;; BUILD TITLE ARRAY COMMAND
;; ============================================================

(defun c:BUILDTITLEARRAY
  (
    /
    ss
    i
    ent
    data
    ip
    cell
    row
    col
    text
    entries
    count
  )


  (princ
    "\nBuilding title array..."
  )


  ;; ==========================================================
  ;; DATABASE SEARCH
  ;; ==========================================================
  ;;
  ;; Use the exact same source layer as BUILDINDEX.
  ;;
  ;; Nothing on TITLE-INDEX is modified.

  (setq ss

    (ssget

      "_X"

      (list

        '(0 . "MTEXT")

        (cons
          8
          DI-TITLE-LAYER
        )

      )
    )
  )


  ;; ==========================================================
  ;; PROCESS TITLE MTEXT
  ;; ==========================================================

  (if ss

    (progn

      (setq i 0)

      (setq entries nil)


      (while

        (<
          i
          (sslength ss)
        )


        ;; Get entity.

        (setq ent
          (ssname ss i)
        )


        ;; Get entity data.

        (setq data
          (entget ent)
        )


        ;; Get insertion point.

        (setq ip
          (cdr
            (assoc 10 data)
          )
        )


        (if ip

          (progn

            ;; Use the EXISTING working grid-cell function.

            (setq cell

              (DI-GET-CELL

                (car ip)

                (cadr ip)

              )
            )


            ;; Only accept titles that BUILDINDEX
            ;; considers valid grid titles.

            (if cell

              (progn

                (setq row
                  (car cell)
                )


                (setq col
                  (cadr cell)
                )


                ;; Use the EXISTING text extraction
                ;; and cleaning functions.

                (setq text

                  (DI-CLEAN-TEXT

                    (DI-GET-TEXT ent)

                  )
                )


                ;; Ignore blank titles.

                (if

                  (> 
                    (strlen text)
                    0
                  )

                  (setq entries

                    (cons

                      (list

                        row
                        col
                        text

                      )

                      entries

                    )
                  )
                )
              )
            )
          )
        )


        (setq i
          (1+ i)
        )
      )
    )
  )


  ;; ==========================================================
  ;; SORT
  ;; ==========================================================
  ;;
  ;; IMPORTANT:
  ;;
  ;; This calls the EXISTING DI-SORT-TITLES function.
  ;; No duplicate sorting function is defined here.

  (setq entries

    (DI-SORT-TITLES
      entries
    )

  )


  ;; ==========================================================
  ;; COUNT
  ;; ==========================================================

  (setq count
    (length entries)
  )


  ;; ==========================================================
  ;; CREATE ARRAY
  ;; ==========================================================

  (if

    (> count 0)

    (progn

      ;; Create TITLE-ARRAY layer if necessary.

      (DI-MAKE-TITLE-ARRAY-LAYER)


      ;; Delete only the previously generated
      ;; TITLE-ARRAY MTEXT.

      (DI-DELETE-TITLE-ARRAY)


      ;; Generate the new array.

      (DI-BUILD-TITLE-ARRAY
        entries
      )


      (princ

        (strcat

          "\nTitle array updated: "

          (itoa count)

          " titles created."

        )
      )
    )


    ;; If nothing was found, do NOT delete
    ;; an existing title array.

    (princ

      "\nNo valid titles found. Existing title array was left unchanged."

    )
  )


  (princ)
)


;; ============================================================
;; LOAD MESSAGE
;; ============================================================

(princ
  "\nTitle Array loaded. Type BUILDTITLEARRAY to run."
)

(princ)