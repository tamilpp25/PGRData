--- 新矿区章节开放蓝点
local XRedPointScoreTowerNewChapter = {}

function XRedPointScoreTowerNewChapter.Check(ignoreActivityCheck)

    if not ignoreActivityCheck then
        if not XMVCA.XScoreTower:GetIsOpen(true) then
            return false
        end
    end
    
    return XMVCA.XScoreTower:IsShowChapterRedPoint()
end

return XRedPointScoreTowerNewChapter