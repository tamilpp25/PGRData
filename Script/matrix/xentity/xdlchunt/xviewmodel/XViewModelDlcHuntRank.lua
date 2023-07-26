local XDlcHuntRankBoss = require("XEntity/XDlcHunt/XDlcHuntRankBoss")

---@class XViewModelDlcHuntRank
local XViewModelDlcHuntRank = XClass(nil, "XViewModelDlcHuntRank")

function XViewModelDlcHuntRank:Ctor(chapterId)
    self._ChapterIdSelected = chapterId or 1
end

function XViewModelDlcHuntRank:GetTabData()
    local result = {}
    local allChapter = XDataCenter.DlcHuntManager.GetAllChapters()
    for chapterId, chapter in pairs(allChapter) do
        result[#result + 1] = chapter
    end
    return result
end

function XViewModelDlcHuntRank:GetDataProvider(chapterId)
    return {
        XDlcHuntRankBoss.New(),
        XDlcHuntRankBoss.New(),
        XDlcHuntRankBoss.New(),
        XDlcHuntRankBoss.New(),
        XDlcHuntRankBoss.New(),
    }
end

function XViewModelDlcHuntRank:GetMyData()
    return XDlcHuntRankBoss.New()
end

return XViewModelDlcHuntRank