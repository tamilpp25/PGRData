-- 收藏品样式脚本，负责不同布局样式的收藏品

local XUiCollectionStyle = XClass(nil, "XUiCollectionStyle")

function XUiCollectionStyle:Ctor(ui, chapter)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Chapter = chapter
    XTool.InitUiObject(self)

    self:Refresh()
end

function XUiCollectionStyle:Refresh()
    self:SetIcon()
    self:SetScore()
end

function XUiCollectionStyle:SetIcon()
    if self.RImIcon then
        if self.Chapter.MedalImg ~= nil and not self.Chapter.IsLock then
            self.RImIcon:SetRawImage(self.Chapter.MedalImg)
            self.RImIcon.gameObject:SetActiveEx(true)
        else
            self.RImIcon.gameObject:SetActiveEx(false)
        end
    end
end

function XUiCollectionStyle:SetScore()
    if self.TextScore then
        local showScore = self.Chapter.ShowScore ~= XMedalConfigs.ShowScore.OFF
        self.TextScore.gameObject:SetActiveEx(self.Chapter.Score > 0 and showScore)

        if self.Chapter.Type == XMedalConfigs.MedalType.Experience then
            local curLevel, _ = XMedalConfigs.GetSpecialCollectionCurLevelAndNextScoreByScore(self.Chapter.Id, self.Chapter.Score)
            self.TextScore.text = curLevel
            if showScore then
                self:SetScoreTextSize(curLevel)
            end
        else
            self.TextScore.text = self.Chapter.Score
            if showScore then
                self:SetScoreTextSize(self.Chapter.Score)
            end
        end
    end
end

---
--- 根据'score'的位数设置self.ScoreTxt的字体大小
---@param score number
function XUiCollectionStyle:SetScoreTextSize(score)
    local fontSize = XDataCenter.MedalManager.GetScoreSize(score, self.RImIcon.rectTransform.rect.width)
    if fontSize then
        self.TextScore.fontSize = fontSize
    end
end

return XUiCollectionStyle