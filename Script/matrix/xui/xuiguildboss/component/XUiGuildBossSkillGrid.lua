--工会boss技能grid组件
local XUiGuildBossSkillGrid = XClass(nil, "XUiGuildBossSkillGrid")

function XUiGuildBossSkillGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

--stageInfo Type is XTableGuildBossStageInfo
function XUiGuildBossSkillGrid:Init(stageInfo, levelData, order)
    self.StageInfo = stageInfo
    local buffInfo = XGuildBossConfig.GetBuff(levelData.EffectId)
    local currCount = levelData.CurEffectCount --nzwjV3
    local totalEffectCount = levelData.TotalEffectCount --nzwjV3
    self.RImgIcon:SetRawImage(buffInfo.Icon)
    self.TxtName.text = buffInfo.Name
    -- self.ImgProgress.fillAmount = currCount / totalEffectCount
    -- self.TxtProgress.text = CSXTextManagerGetText("GuildBossSkillProgress", currCount, totalEffectCount)
    self.TxtProgressCur.text = currCount
    self.TxtProgressMax.text = "/"..totalEffectCount
    self.TxtDis.text = buffInfo.Dis
    if order then
        self.TxtCode.text = self.StageInfo.Code .. order
    end

    self.IsGet.gameObject:SetActiveEx(false)
end

return XUiGuildBossSkillGrid