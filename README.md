**Application:** AutoCAD LT 2026  
**Tool:** auto-title.lsp  
**Commands:** `BUILDINDEX` and `BUILDTITLEARRAY`

## 1. Purpose

This tool automatically generates two outputs from drawing titles placed on the `TITLE-INDEX` layer:

- **Drawing Index:** A numbered list of drawing titles contained in a single MTEXT object on the `DRAWING-INDEX` layer.
- **Title Array:** Individual MTEXT objects containing each drawing title on the `TITLE-ARRAY` layer.
    
The tool reads titles from the drawing template, sorts them by their grid position, and generates the outputs automatically.

Running `BUILDINDEX` also runs `BUILDTITLEARRAY`, so both outputs are normally updated with one command.

Using this tool, drawing titling is done within the grid space directly. This makes adding, removing, or re-ordering drawings within a drawing set much more flexible. 

## 2. Requirements

Before using the tool, confirm the following:

- AutoCAD LT 2026 is installed.
- Your drawing uses the latest `.dwt` for new projects. 

**Important:** The tool is configured specifically for TMBA's standard project template; it will not work for arbitrary grid-spaced templates. 

## 3. Installation

This SOP follows the standard `APPLOAD` and Startup Suite process used in the rest of our LISP tools:

1. Type `APPLOAD` into the AutoCAD command line and press **Enter**.
2. Browse to `\AutoCAD\_Templates & Tools\AutoCAD-Tools\lsp`
3. Select `auto-title.lsp` and click **Load**.
4. Confirm that the command line outputs the following:
   
>auto-title.lsp successfully loaded.

5.  Click **Contents…** in the Startup Suite window next to the **Loaded Applications** list in `APPLOAD`. A dialog box will open. 
6. Click **Add** in the dialog box, browse to `auto-title.lsp`, and click **Open**.
7. Back in the dialog box, `auto-title.lsp` will appear alongside `acaddoc.lsp` from Kevin's Tools.
8. A security prompt will appear when the tool is first loaded. Click **Always Load**.
9. Restart AutoCAD and confirm the command line outputs the following:

>auto-title.lsp successfully loaded.

>Drawing Index loaded. Type BUILDINDEX to run.

>Title Array loaded. Type BUILDTITLEARRAY to run.

10. You're done!
## 4. Preparing the Drawing

1. Load the latest TMBA Project Template from `\AutoCAD\_Templates & Tools\CAD templates`.
2. Drawing titles for **General Notes** and **Communication Riser Diagram** will be on the `TITLE-INDEX` layer, placed at specific coordinates within each their respective grid space. Use `CTRL+SHIFT+C` to copy these MTEXT objects from the corner of a grid space.
3. Paste the `TITLE-INDEX` MTEXT object into the following grid spaces and title them accordingly, e.g. "Master Control Panel". Repeat for all applicable drawings.
4. Once all of your drawings are titled, type `BUILDINDEX` into the command line and press **Enter.** Your drawing index on the title page will be generated, and the viewport title array for each paper space layout will be populated.
### Operational notes

- Each title must be positioned in the designated title location within its drawing-grid cell. Make sure to Copy with Base Point `(CTRL+SHIFT+C)` to standardize title placement. If a title lays outside of the standard insertion point (within a small tolerance), it will be skipped.
- The tool cleans up any MTEXT formatting such as underlining, bolding, and italicizing. Always review the generated output for unexpected formatting or text.
- The latest TMBA Project Template will retain the original linked title block as a backup method, moved off to the side. If for some reason this `.lsp` isn't working, our original titling capability can be used instead.
## 6. Understanding the Output

|Layer|Contents|Behavior|
|---|---|---|
|`TITLE-INDEX`|Original drawing titles|Source data; not modified by the tool|
|`DRAWING-INDEX`|One numbered MTEXT list|Replaced when a new valid index is generated|
|`TITLE-ARRAY`|Individual MTEXT title objects|Replaced when a new valid title array is generated|

### Drawing Index

The Drawing Index contains sequential numbering and drawing titles in grid order.

It is generated as one MTEXT object. The tool supports long lists by dividing the text internally into multiple text segments while preserving one continuous MTEXT object.

### Title Array

The Title Array creates one MTEXT object per title. These objects are arranged vertically using the configured spacing.

The Title Array contains the titles only, without the numbered prefixes used in the Drawing Index.

## 7. Troubleshooting

### The command is not recognized

**Possible causes:**

- The LISP file has not been loaded.
- The file failed to load.
- AutoCAD was restarted and automatic loading is not configured.

**Resolution:**

1. Run `APPLOAD`.
2. Load the approved LISP file.
3. Confirm the load message.
4. Run `BUILDINDEX` again.

### No valid titles are found

**Possible causes:**

- Titles are not on `TITLE-INDEX`.
- Titles are TEXT objects rather than MTEXT objects.
- Titles are outside the configured grid.
- MTEXT insertion points do not match the expected title positions.
- Titles contain no meaningful text after formatting is cleaned up.

**Resolution:**

1. Confirm the source layer is named `TITLE-INDEX`.
2. Confirm that the title objects are MTEXT.
3. Check that the titles are in their expected grid locations.
4. Verify that the correct drawing template is being used.

If the problem persists, contact the tool maintainer rather than changing the LISP configuration.

### The Drawing Index is missing titles

**Resolution:**

1. Check whether the missing titles appear in the Title Array.
2. Confirm that the missing source titles are on `TITLE-INDEX`.
3. Check their insertion points and grid positions.
4. Review the command-line messages for errors.

If the Title Array contains the missing titles but the Drawing Index does not, report this to the tool maintainer. Do not manually edit the LISP to work around the issue.

### The Drawing Index stops displaying partway through the list

The Drawing Index is a single MTEXT object, whereas the Title Array uses individual MTEXT objects. The index generator uses multiple DXF text segments to support longer lists.

If the output is truncated, confirm that the latest LISP version is loaded. If necessary, reload the file and regenerate the index.

### The Title Array is missing or outdated

Run `BUILDTITLEARRAY` to regenerate it.

If the output is still incorrect, verify the source titles and their placement on `TITLE-INDEX`.

### The output appears in the wrong location or has the wrong formatting

The insertion points, text height, text style, spacing, and layer assignments are controlled by the LISP configuration.

Do not change these settings unless you are authorized to maintain the tool.

## 8. Important Operating Rules

- **Do not edit the source title layer through the generated output.** Make title corrections on `TITLE-INDEX`, then regenerate the outputs.
- **Do not rename the designated layers** unless the tool is updated and tested accordingly.
- **Do not assume the tool supports every drawing template.** Use the approved template.
- **Review the generated outputs before issuing drawings.** Confirm that all expected titles are present, correctly ordered, and readable.
## 9. Reporting Issues

When reporting a problem, provide:

- The drawing filename and template being used.
- The number of titles expected and the number generated.
- The affected title or grid cell, if applicable.
- Any error messages displayed in the command line.
- A screenshot of the source grid and generated output, if possible.

Do not modify the core LISP functionality to troubleshoot an issue unless you are the designated maintainer.

## 10. Quick Reference

|Task|Command|
|---|---|
|Load the LISP file|`APPLOAD`|
|Generate the Drawing Index and Title Array|`BUILDINDEX`|
|Generate only the Title Array|`BUILDTITLEARRAY`|
