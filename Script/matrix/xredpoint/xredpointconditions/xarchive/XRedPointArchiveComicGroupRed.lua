--- 漫画组红点
local XRedPointArchiveComicGroupRed = {}

local Events = nil

function XRedPointArchiveComicGroupRed.GetSubEvents()
    Events = Events or
            {
                XRedPointEventElement.New(XEventId.EVENT_ARCHIVE_MARK_COMIC),
                XRedPointEventElement.New(XEventId.EVENT_ARCHIVE_NEW_COMIC),
            }
    return Events
end

function XRedPointArchiveComicGroupRed.Check(groupId)
    return XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Archive) and XMVCA.XArchive.ComicArchiveCom:CheckComicGroupRedShow(groupId)
end 

return XRedPointArchiveComicGroupRed