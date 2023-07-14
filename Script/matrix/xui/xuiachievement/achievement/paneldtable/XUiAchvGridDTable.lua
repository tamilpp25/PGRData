--================
--成就动态列表项控件
--================
local XUiAchvGridDTable = XClass(XDynamicGridTask, "XUiAchvGridDTable")

function XUiAchvGridDTable:RefreshRare()
    if self.Data then
        local achievement = XDataCenter.AchievementManager.GetAchievementByTaskId(self.Data.Id)
        if achievement then
            local quality = achievement:GetQuality()
            if not self.ImageTrophyRare then
                self.ImageTrophyRare = XUiHelper.TryGetComponent(self.Transform, "PanelAnimation/ImageTrophyRare", "Image")
            end
            if self.ImageTrophyRare then
                local path = CS.XGame.ClientConfig:GetString("AchievementRareIconQuality" .. quality)
                if path then
                    self.ImageTrophyRare:SetSprite(path)
                end
            end
        end
    end
end

return XUiAchvGridDTable