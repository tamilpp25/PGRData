local XUiMaverick2CharacterExchangeGrid = XClass(nil, "UiMaverick2CharacterExchangeGrid")

function XUiMaverick2CharacterExchangeGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.IsUnlock = true
    self.IsForbid = false

    XTool.InitUiObject(self)
    self.RImgQuality.gameObject:SetActiveEx(false)
end

function XUiMaverick2CharacterExchangeGrid:Refresh(robotCfg, stageId)
    self.RobotCfg = robotCfg
    self.StageId = stageId

    -- 头像
    local entity = XRobotManager.GetRobotById(robotCfg.RobotId)
    local characterViewModel = entity:GetCharacterViewModel()
    self.RImgHeadIcon:SetRawImage(characterViewModel:GetSmallHeadIcon())

    -- 名字
    self.TxtName.text = robotCfg.Name

    -- 是否解锁这个角色
    self.IsForbid = XDataCenter.Maverick2Manager.IsRobotForbid(robotCfg.RobotId, self.StageId)
    self.IsUnlock = XDataCenter.Maverick2Manager.IsRobotUnlock(robotCfg.RobotId)

    -- 未解锁和禁用显示
    self.RImgHeadIcon.gameObject:SetActiveEx(self.IsUnlock)
    self.RImgUnGet.gameObject:SetActiveEx(not self.IsUnlock)
    self.ImgLock.gameObject:SetActiveEx(self.IsForbid)
end

function XUiMaverick2CharacterExchangeGrid:ShowSelect(isSelect)
    self.PanelSelected.gameObject:SetActiveEx(isSelect)
end

return XUiMaverick2CharacterExchangeGrid