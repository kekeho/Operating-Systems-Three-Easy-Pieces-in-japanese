import os
import strutils


proc replaceImagePath(folder: string, line: string): string =
  let idx = line.find("./img")
  if idx < 0:
    return line

  return line[0..idx-1] & "../" & folder & replaceImagePath(folder, line[idx+1..line.len-1])


proc replaceInvalidStr(line: string): string =
  return line.replace("⊕", " \\xor ")


when isMainModule:
  # Concat File
  block:
    let allfp: File = open("build/content.md", FileMode.fmWrite)
    defer:
      allfp.close()

    # Concat
    for f in walkFiles("../*/*.md"):
      echo f
      block:
        let mdfp: File = open(f, FileMode.fmRead)
        defer:
          mdfp.close()

        # 章
        let filepathseq = f.split('/')
        if filepathseq[filepathseq.len-1] == "01.md":
          allfp.writeLine("\\part{Virtualization}")
        if filepathseq[filepathseq.len-1] == "26.md":
          allfp.writeLine("\\part{Concurrency}")
        if filepathseq[filepathseq.len-1] == "36.md":
          allfp.writeLine("\\part{Persistence}")

        # 内容書き込み
        var line: string = ""
        while mdfp.readLine(line):
          if (line.find("[prev]") != -1) or (line.find("[next]") != -1):
            continue

          line = replaceImagePath(f.split('/')[1], line)
          line = replaceInvalidStr(line)
          allfp.writeLine(line)
        
        allfp.writeLine("\\newpage")
        allfp.writeLine("")

  # pandoc
  echo "md -> tex"
  let resPandoc = os.execShellCmd("pandoc build/content.md -o build/content_before.tex")
  if resPandoc != 0:
    echo "An error has occured! (in pandoc)"
    quit(resPandoc)
  
  block:
    let texbefore: File = open("build/content_before.tex", FileMode.fmRead)
    let texafter: File = open("build/content.tex", FileMode.fmWrite)
    defer:
      texbefore.close()
      texafter.close()
    
    var line: string = ""
    while texbefore.readLine(line):
      line = line.replace("\\section", "\\section*")
      line = line.replace("\\subsection", "\\subsection*")
      line = line.replace("\\subsubsection", "\\subsubsection*")

      texafter.writeLine(line)
  
  # build
  echo "tex -> dvi"
  let resPlatex = os.execShellCmd("platex build/jostep.tex")
  if resPlatex != 0:
    echo "An error has occured (in platex)"
    quit(resPlatex)
  let resDvi2pdf = os.execShellCmd("dvipdfmx jostep.dvi")
  if resDvi2pdf != 0:
    echo "An error has occured (in dvipdfmx)"
    quit(resDvi2pdf)
