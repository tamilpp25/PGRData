--- 指定漫画章节红点
local XRedPointArchiveComicRed = {}

local Events = nil

function XRedPointArchiveComicRed.GetSubEvents()
    Events = Events or
            {
                XRedPointEventElement.New(XEventId.EVENT_ARCHIVE_MARK_COMIC),
                XRedPointEventElement.New(XEventId.EVENT_ARCHIVE_NEW_COMIC),
            }
    return Events
end

function XRedPointArchiveComicRed.Check(chapterId)
    return XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Archive) and XMVCA.XArchive.ComicArchiveCom:CheckComicChapterRedShow(chapterId)
end 

return XRedPointArchiveComicRed