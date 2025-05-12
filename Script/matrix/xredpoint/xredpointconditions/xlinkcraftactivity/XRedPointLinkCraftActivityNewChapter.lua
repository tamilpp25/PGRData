local XRedPointLinkCraftActivityNewChapter = {}

function XRedPointLinkCraftActivityNewChapter.Check(chapterId)
    if XTool.IsNumberValid(chapterId) then
        return XMVCA.XLinkCraftActivity:CheckChapterIsNewById(chapterId)
    end
    
    return XMVCA.XLinkCraftActivity:CheckHasNewChapter()
end

return XRedPointLinkCraftActivityNewChapter