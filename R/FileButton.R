ImportFileButton <- function(label=gettext("Import", domain = "R-RQDA"), container,...)
{
  ImpFilB <- gbutton(label, container=container, handler=function(h,...){
      path <- gfile(type="open",filter=list("text files" = list(mime.types = c("text/plain")),
              "All files" = list(patterns = c("*"))))
      if (path!=""){
        Encoding(path) <- "UTF-8" ## have to convert, otherwise, can not find the file.
        ImportFile(path,container=.rqda$qdacon)
         FileNamesUpdate()
      }
    }
          )
  assign("ImpFilB",ImpFilB,envir=button)
  gtkWidgetSetSensitive(button$ImpFilB$widget,FALSE)
}

NewFileButton <- function(label=gettext("New", domain = "R-RQDA"), container,...)
{
    NewFilB <- gbutton(label, container=container, handler=function(h,...){
        if (is_projOpen(envir = .rqda, conName = "qdacon", message = FALSE)) {
            AddNewFileFun()
        }
    }
                       )
    assign("NewFilB",NewFilB,envir=button)
    enabled(NewFilB) <- FALSE
}

DeleteFileButton <- function(label=gettext("Delete", domain = "R-RQDA"), container,...){
  DelFilB <- gbutton(label,container=container,handler=function(h,...){
              SelectedFile <- svalue(.rqda$.fnames_rqda)
              Encoding(SelectedFile) <- "UTF-8"
              ## if the project open and a file is selected, then continue the action
              del <- gconfirm(ngettext(length(SelectedFile),
                                       "Really delete the file?",
                                       "Really delete the files?", domain = "R-RQDA"), icon="question")
              if (isTRUE(del)) {
                ## con <- .rqda$qdacon
                  for (i in SelectedFile){
                    i <- enc(i)
                fid <- dbGetQuery(.rqda$qdacon, sprintf("select id from source where name='%s'",i))$id
                dbGetQuery(.rqda$qdacon, sprintf("update source set status=0 where name='%s'",i))
                ## set the status of the selected file to 0
                dbGetQuery(.rqda$qdacon, sprintf("update caselinkage set status=0 where fid=%i",fid))
                dbGetQuery(.rqda$qdacon, sprintf("update treefile set status=0 where fid=%i",fid))
                dbGetQuery(.rqda$qdacon, sprintf("update coding set status=0 where fid=%i",fid))
                ## set the status of the related case/f-cat to 0
                }
                  FileNamesUpdate()
                  UpdateWidget(".fnames_rqda",from=SelectedFile,to=NULL)
              }
          },
          action=list(envir=.rqda,conName="qdacon")
          )
  assign("DelFilB",DelFilB,envir=button)
  gtkWidgetSetSensitive(button$DelFilB$widget,FALSE)
}

ViewFileButton <-  function(label=gettext("Open", domain = "R-RQDA"), container,...)
{
  VieFilB <- gbutton(label,container=container,handler=function(h,...)
          {
            ViewFileFun(FileNameWidget=.rqda$.fnames_rqda)
          }
          )
  assign("VieFilB",VieFilB,envir=button)
  gtkWidgetSetSensitive(button$VieFilB$widget,FALSE)
}


File_MemoButton <- function(label=gettext("Memo", domain = "R-RQDA"), container=.rqda$.files_button,FileWidget=.rqda$.fnames_rqda,...){
  ## memo of selected file.
  FilMemB <- gbutton(label, container=container, handler=function(h,...) {
      MemoWidget(gettext("File", domain = "R-RQDA"),FileWidget,"source")
  }
          )
  assign("FilMemB",FilMemB,envir=button)
  gtkWidgetSetSensitive(button$FilMemB$widget,FALSE)
}

File_RenameButton <- function(label=gettext("Rename", domain = "R-RQDA"), container=.rqda$.files_button,FileWidget=.rqda$.fnames_rqda,...)
{
  ## rename of selected file.
  FilRenB <- gbutton(label, container=container, handler=function(h,...) {
      selectedFN <- svalue(FileWidget)
      if (length(selectedFN)==0){
        gmessage(gettext("Select a file first.", domain = "R-RQDA"),icon="error",container=TRUE)
      }
      else {
        ## get the new file names
        NewFileName <- ginput(gettext("Enter new file name. ", domain = "R-RQDA"),text=selectedFN, icon="info")
        if (!is.na(NewFileName)) {
          Encoding(NewFileName) <- "UTF-8"
          ## otherwise, R transform it into local Encoding rather than keep it as UTF-8
          ## Newfilename <- iconv(codename,from="UTF-8") ## now use UTF-8 for SQLite data set.
          ## update the name in source table by a function
          rename(selectedFN,NewFileName,"source")
          FileNamesUpdate()
          UpdateWidget(".fnames_rqda",from=selectedFN,to=NewFileName) ## speed it up by bypassing access the database.
          ## (name is the only field should be modifed, as other table use fid rather than name)
        }
      }
    }
          )
  FilRenB
  assign("FilRenB",FilRenB,envir=button)
  gtkWidgetSetSensitive(button$FilRenB$widget,FALSE)
}

FileAttribute_Button <- function(label=gettext("Attribute", domain = "R-RQDA"),container=.rqda$.files_button,FileWidget=.rqda$.fnames_rqda,...)
{
    FileAttrB <- gbutton(label, container=container, handler=function(h,...) {
        if (is_projOpen(envir=.rqda,conName="qdacon")) {
            Selected <- svalue(FileWidget)
            if (length(Selected !=0 )){
                fileId <- RQDAQuery(sprintf("select id from source where status=1 and name='%s'",
                                            enc(Selected)))[,1]
                FileAttrFun(fileId=fileId,title=Selected)
            }
        }
    }
                         )
    FileAttrB
    assign("FileAttrB",FileAttrB,envir=button)
    enabled(FileAttrB) <- FALSE
}

AddNewFileFun <- function(){
  if (is_projOpen(envir=.rqda,"qdacon")) {
    if (exists(".AddNewFileWidget",envir=.rqda) && isExtant(.rqda$.AddNewFileWidget)) {
      dispose(.rqda$.AddNewFileWidget)
    } ## close the widget if open
    gw <- gwindow(title="Add a new file", parent=getOption("widgetCoordinate"),
                  width = getOption("widgetSize")[1],
                  height = getOption("widgetSize")[2])
    mainIcon <- system.file("icon", "mainIcon.png", package = "RQDA")
    gw$widget$SetIconFromFile(mainIcon)
    assign(".AddNewFileWidget",gw,envir=.rqda)
    assign(".AddNewFileWidget2",gpanedgroup(horizontal = FALSE, container=get(".AddNewFileWidget",envir=.rqda)),envir=.rqda)
    saveFileFun <- function() {
      ## require a title for the file
      Ftitle <- ginput(gettext("Enter the title", domain = "R-RQDA"), icon="info")
      if (!is.na(Ftitle)) {
        Ftitle <- enc(Ftitle,"UTF-8")
        if (nrow(dbGetQuery(.rqda$qdacon,sprintf("select name from source where name='%s'",Ftitle)))!=0) {
          Ftitle <- paste("New",Ftitle)
        }## Make sure it is unique
        content <- svalue(textW)
        content <- enc(content,encoding="UTF-8") ## take care of double quote.
        maxid <- dbGetQuery(.rqda$qdacon,"select max(id) from source")[[1]] ## the current one
        nextid <- ifelse(is.na(maxid),0+1, maxid+1) ## the new one/ for the new file
        ans <- dbGetQuery(.rqda$qdacon,sprintf("insert into source (name, file, id, status,date,owner )
                             values ('%s', '%s',%i, %i, '%s', '%s')",
                                               Ftitle,content, nextid, 1,date(),.rqda$owner))
        if (is.null(ans)){
          svalue(textW) <- "" ## clear the content.
          FileNamesUpdate()
          enabled(button$AddNewFilB) <- FALSE
          enabled(button$AddNewFilB2) <- FALSE
      }
        return(TRUE)
    } else {
        return(FALSE)
    }
  } ## end of saveFileFun

    gl <- glayout(homogeneous=T,container=get(".AddNewFileWidget2",envir=.rqda))
    AddNewFilB <- gbutton(gettext("Save To Project", domain = "R-RQDA"), handler=function(h,...){saveFileFun()})
    enabled(AddNewFilB) <- FALSE
    assign("AddNewFilB",AddNewFilB,envir=button)
    AddNewFilB2 <- gbutton(gettext("Save and close", domain = "R-RQDA"), handler=function(h,...){
        suc <- saveFileFun()
        if (suc) dispose(.rqda$.AddNewFileWidget)
    }
                           )
    enabled(AddNewFilB2) <- FALSE
    assign("AddNewFilB2",AddNewFilB2,envir=button)
    gl[1,1] <- AddNewFilB
    gl[1,2] <- AddNewFilB2
    tmp <- gtext(container=get(".AddNewFileWidget2",envir=.rqda))
    font <- pangoFontDescriptionFromString(.rqda$font)
    gtkWidgetModifyFont(tmp$widget,font) ## set the default fontsize
    assign(".AddNewFileWidgetW",tmp,envir=.rqda)
    textW <- get(".AddNewFileWidgetW",envir=.rqda)
    addHandlerKeystroke(.rqda$.AddNewFileWidgetW,handler=function(h,...){
      enabled(button$AddNewFilB) <- TRUE
      enabled(button$AddNewFilB2) <- TRUE
    })
    addhandlerunrealize(.rqda$.AddNewFileWidgetW,handler=function(h,...){
      rm("AddNewFilB",envir=button)
      rm(".AddNewFileWidgetW",".AddNewFileWidget",".AddNewFileWidget2",envir=.rqda)
      FALSE
    })
    ## svalue(.rqda$.AddNewFileWidget2) <- 0.03999
  }
}


## pop-up menu of add to case and F-cat from Files Tab
## The translations must be created at run time, otherwise they will not work.
GetFileNamesWidgetMenu <- function()
{
  FileNamesWidgetMenu <- list()
  FileNamesWidgetMenu[[gettext("Add New File ...", domain = "R-RQDA")]]$handler <- function(h, ...) {
    if (is_projOpen(envir = .rqda, conName = "qdacon", message = FALSE)) {
      AddNewFileFun()
    }
  }
  FileNamesWidgetMenu[[gettext("Add To Case ...", domain = "R-RQDA")]]$handler <- function(h, ...) {
    if (is_projOpen(envir = .rqda, conName = "qdacon", message = FALSE)) {
      AddFileToCaselinkage()
      UpdateFileofCaseWidget()
    }
  }
  FileNamesWidgetMenu[[gettext("Add To File Category ...", domain = "R-RQDA")]]$handler <- function(h, ...) {
    if (is_projOpen(envir = .rqda, conName = "qdacon", message = FALSE)) {
      AddToFileCategory()
      UpdateFileofCatWidget()
    }
  }
  FileNamesWidgetMenu[[gettext("Add/modify Attributes of The Open File...", domain = "R-RQDA")]]$handler <- function(h,...){
    if (is_projOpen(envir=.rqda,conName="qdacon")) {
      Selected <- tryCatch(svalue(.rqda$.root_edit),error=function(e){NULL})
      if (!is.null(Selected)){
        fileId <- RQDAQuery(sprintf("select id from source where status=1 and name='%s'",
                                    enc(Selected)))[,1]
        FileAttrFun(fileId=fileId,title=Selected)
      }
  }}
  FileNamesWidgetMenu[[gettext("View Attributes", domain = "R-RQDA")]]$handler <- function(h,...){
    if (is_projOpen(envir=.rqda,conName="qdacon")) {
      viewFileAttr()
    }
  }

  FileNamesWidgetMenu[[gettext("Codings of selected file(s)", domain = "R-RQDA")]]$handler <- function(h,...){
    if (is_projOpen(envir=.rqda,conName="qdacon")) {
      fid =getFileIds(type="selected")
      if (length(fid)>0) {
        getCodingsFromFiles(Fid=fid)
      } else gmessage(gettext("No coded file is selected.", domain = "R-RQDA"))
    }
  }

  FileNamesWidgetMenu[[gettext("Export File Attributes", domain = "R-RQDA")]]$handler <- function(h,...){
    if (is_projOpen(envir=.rqda,conName="qdacon")) {
      fName <- gfile(type='save',filter=list("csv"=list(pattern=c("*.csv"))))
      Encoding(fName) <- "UTF-8"
      if (length(grep(".csv$",fName))==0) fName <- sprintf("%s.csv",fName)
      write.csv(GetAttr("file"), row.names=FALSE, file=fName, na="")
    }
  }
  FileNamesWidgetMenu[[gettext("Edit Selected File", domain = "R-RQDA")]]$handler <- function(h, ...) {
    EditFileFun()
  }
  FileNamesWidgetMenu[[gettext("Export Coded file as HTML", domain = "R-RQDA")]]$handler <- function(h, ...) {
    if (is_projOpen(envir = .rqda, conName = "qdacon", message = FALSE)) {
      path=gfile(type="save",text = gettext("Type a name for the exported codings and click OK.", domain = "R-RQDA"))
      if (!is.na(path)){
        Encoding(path) <- "UTF-8"
        path <- sprintf("%s.html",path)
        exportCodedFile(file=path,getFileIds(type="selected")[1])
  }}}

  ## a=gtext("this is a test for search a.",container=T)
  ## b<-a$widget$GetBuffer()
  ## b$GetIterAtOffset(0)
  ## i0=b$GetIterAtOffset(0)
  ## s0=i0$iter$ForwardSearch("a","GTK_TEXT_SEARCH_VISIBLE_ONLY")
  ## s0$match.start$GetOffset()
  ## s0$match.end$GetOffset()

  FileNamesWidgetMenu[[gettext("File Annotations", domain = "R-RQDA")]]$handler <- function(h,...){
    if (is_projOpen(envir=.rqda,conName="qdacon")) {
      print(getAnnos())
  }}
  FileNamesWidgetMenu[[gettext("File Memo", domain = "R-RQDA")]]$handler <- function(h,...){
    if (is_projOpen(envir=.rqda,conName="qdacon")) {
      MemoWidget(gettext("File", domain = "R-RQDA"),.rqda$.fnames_rqda,"source")
      ## see CodeCatButton.R  for definition of MemoWidget
    }
  }
  FileNamesWidgetMenu[[gettext("Import PDF Highlights via rjpod (selector)", domain = "R-RQDA")]]$handler <- function(h,...){
    importPDFHL(engine="rjpod")
  }
  FileNamesWidgetMenu[[gettext("Import PDF Highlights via rjpod (file path)", domain = "R-RQDA")]]$handler <- function(h,...){
    fpath=ginput(gettext("Enter a pdf file path", domain = "R-RQDA"),con=T)
    importPDFHL(file=fpath, engine="rjpod")
  }
  FileNamesWidgetMenu[[gettext("Open Selected File", domain = "R-RQDA")]]$handler <- function(h,...){
    ViewFileFun(FileNameWidget=.rqda$.fnames_rqda)
  }
  FileNamesWidgetMenu[[gettext("Open Previous Coded File", domain = "R-RQDA")]]$handler <- function(h,...){
    if (is_projOpen(envir = .rqda, conName = "qdacon", message = FALSE)) {
      fname <- RQDAQuery("select name from source where id in ( select fid from coding where rowid in (select max(rowid) from coding where status=1))")$name
      if (length(fname)!=0)  fname <- enc(fname,"UTF-8")
      ViewFileFunHelper(FileName=fname)
  }}
  FileNamesWidgetMenu[[gettext("Search for a Word", domain = "R-RQDA")]]$handler <- function(h, ...) {
    if (exists(".openfile_gui",envir=.rqda) && isExtant(.rqda$.openfile_gui)) {
      SearchButton(.rqda$.openfile_gui)
    }
  }
  FileNamesWidgetMenu[[gettext("Search all files ...", domain = "R-RQDA")]]$handler <- function(h, ...) {
    if (is_projOpen(envir = .rqda, conName = "qdacon", message = FALSE)) {
      pattern <- ifelse(is.null(.rqda$lastsearch),"file like '%%'",.rqda$lastsearch)
      pattern <- ginput(gettext("Please input a search pattern.", domain = "R-RQDA"),text=pattern)
      if (!is.na(pattern)){
        tryCatch(SearchFiles(pattern,Widget=".fnames_rqda",is.UTF8=TRUE),error=function(e) gmessage(gettext("Error~~~.", domain = "R-RQDA")),container=TRUE)
        Encoding(pattern) <- "UTF-8"
        assign("lastsearch",pattern,envir=.rqda)
      }
    }
  }
  FileNamesWidgetMenu[[gettext("Show ...", domain = "R-RQDA")]][[gettext("Show All Sorted By Imported Time", domain = "R-RQDA")]]$handler <- function(h, ...) {
    if (is_projOpen(envir = .rqda, conName = "qdacon", message = FALSE)) {
      FileNamesUpdate(FileNamesWidget=.rqda$.fnames_rqda)
      FileNameWidgetUpdate(FileNamesWidget=.rqda$.fnames_rqda,FileId=GetFileId(condition="unconditional",type="all"))
    }
  }
  FileNamesWidgetMenu[[gettext("Show ...", domain = "R-RQDA")]][[gettext("Show Coded Files Sorted by Imported time", domain = "R-RQDA")]]$handler <- function(h,...){
    if (is_projOpen(envir =.rqda,conName="qdacon")) {
      FileNameWidgetUpdate(FileNamesWidget=.rqda$.fnames_rqda,FileId=GetFileId(condition="unconditional",type="coded"))
    }
  }
  FileNamesWidgetMenu[[gettext("Show ...", domain = "R-RQDA")]][[gettext("Show Uncoded Files Sorted by Imported time", domain = "R-RQDA")]]$handler <- function(h, ...) {
    if (is_projOpen(envir = .rqda, conName = "qdacon", message = FALSE)) {
      ## UncodedFileNamesUpdate(FileNamesWidget = .rqda$.fnames_rqda)
      FileNameWidgetUpdate(FileNamesWidget=.rqda$.fnames_rqda,FileId=GetFileId(condition="unconditional",type="uncoded"))
      ## By default, the file names in the widget will be sorted.
    }
  }
  FileNamesWidgetMenu[[gettext("Show ...", domain = "R-RQDA")]][[gettext("Show Files With Annotation", domain = "R-RQDA")]]$handler <- function(h, ...) {
    fileid <- RQDAQuery("select fid from annotation where status=1 group by fid")$fid
    if (length(fileid)!=0) {
      FileNameWidgetUpdate(FileNamesWidget=.rqda$.fnames_rqda,FileId=fileid)
    } else gmessage(gettext("No file with memo.", domain = "R-RQDA"),container=TRUE)
  }
  FileNamesWidgetMenu[[gettext("Show ...", domain = "R-RQDA")]][[gettext("Show Files Without Annotation", domain = "R-RQDA")]]$handler <- function(h, ...) {
    fileid <- RQDAQuery("select id from source where status=1 and id not in (select fid from annotation where status=1 group by fid)")$id
    if (length(fileid)!=0) {
      FileNameWidgetUpdate(FileNamesWidget=.rqda$.fnames_rqda,FileId=fileid)
    } else gmessage(gettext("All files have annotation.", domain = "R-RQDA"),container=TRUE)
  }

  FileNamesWidgetMenu[[gettext("Show ...", domain = "R-RQDA")]][[gettext("Show Files With Memo", domain = "R-RQDA")]]$handler <- function(h, ...) {
    if (is_projOpen(envir = .rqda, conName = "qdacon", message = FALSE)) {
      fileid <- dbGetQuery(.rqda$qdacon,"select id from source where memo is not null")
      if (nrow(fileid)!=0) {
        fileid <- fileid[[1]]
        FileNameWidgetUpdate(FileNamesWidget=.rqda$.fnames_rqda,FileId=fileid)
      } else gmessage(gettext("No file with memo.", domain = "R-RQDA"),container=TRUE)
    }
  }
  FileNamesWidgetMenu[[gettext("Show ...", domain = "R-RQDA")]][[gettext("Show Files Without Memo", domain = "R-RQDA")]]$handler <- function(h, ...) {
    if (is_projOpen(envir = .rqda, conName = "qdacon", message = FALSE)) {
      fileid <- dbGetQuery(.rqda$qdacon,"select id from source where memo is null")
      if (nrow(fileid)!=0) {
        fileid <- fileid[[1]]
        FileNameWidgetUpdate(FileNamesWidget=.rqda$.fnames_rqda,FileId=fileid)
      } else gmessage(gettext("No file is found.", domain = "R-RQDA"),container=TRUE)
    }
  }

  FileNamesWidgetMenu[[gettext("Show ...", domain = "R-RQDA")]][[gettext("Show Files Without File Category", domain = "R-RQDA")]]$handler <- function(h, ...) {
    if (is_projOpen(envir = .rqda, conName = "qdacon", message = FALSE)) {
      fileid <- RQDAQuery("select id from source where status=1 and id not in (select fid from treefile where status=1)")
      if (nrow(fileid)!=0) {
        fileid <- fileid[[1]]
        FileNameWidgetUpdate(FileNamesWidget=.rqda$.fnames_rqda,FileId=fileid)
      } else gmessage(gettext("All are linked with file category.", domain = "R-RQDA"),container=TRUE)
    }
  }
  FileNamesWidgetMenu[[gettext("Show ...", domain = "R-RQDA")]][[gettext("Show Files With No Case", domain = "R-RQDA")]]$handler <- function(h, ...) {
    if (is_projOpen(envir = .rqda, conName = "qdacon", message = FALSE)) {
      fileid <- RQDAQuery("select id from source where status=1 and id not in (select fid from caselinkage where status=1)")
      if (nrow(fileid)!=0) {
        fileid <- fileid[[1]]
        FileNameWidgetUpdate(FileNamesWidget=.rqda$.fnames_rqda,FileId=fileid)
      } else gmessage(gettext("All are linked with cases.", domain = "R-RQDA"),container=TRUE)
    }
  }
  FileNamesWidgetMenu[[gettext("Show Selected File Property", domain = "R-RQDA")]]$handler <- function(h, ...) {
    if (is_projOpen(envir = .rqda, conName = "qdacon", message = FALSE)) {
      ShowFileProperty()
    }
  }
  FileNamesWidgetMenu
}
