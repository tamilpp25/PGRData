--工会boss技能grid组件
local XUiGuildBossSkillGrid = XClass(nil, "XUiGuildBossSkillGrid")

function XUiGuildBossSkillGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

--levelData Type is XTableGuildBossStageInfo
function XUiGuildBossSkillGrid:Init(levelData, progress, order)
    self.LevelData = levelData
    local buffInfo = XGuildBossConfig.GetBuff(self.LevelData.BuffId)
    local levelInfo = XGuildBossConfig.GetBossStageInfo(self.LevelData.Id)
    self.RImgIcon:SetRawImage(levelInfo.Icon)
    self.TxtName.text = buffInfo.Name
    self.ImgProgress.fillAmount = progress / 100
    self.TxtProgress.text = progress .. "%"
    self.TxtDis.text = buffInfo.Dis
    if order then
        self.TxtCode.text = self.LevelData.Code .. order
    end

    if progress >= 100 then
        self.IsGet.gameObject:SetActiveEx(true)
    else
        self.IsGet.gameObject:SetActiveEx(false)
    end
end

return XUiGuildBossSkillGrid