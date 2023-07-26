local XUiMaverick2CharacterRobot = XClass(nil, "UiMaverick2CharacterRobot")

function XUiMaverick2CharacterRobot:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.IsUnlock = true
    self.IsForbid = false

    XTool.InitUiObject(self)
end

function XUiMaverick2CharacterRobot:Refresh(robotCfg, isForbid, isSelect)
    self.RobotCfg = robotCfg
    self.IsForbid = isForbid

    -- 头像
    local entity = XRobotManager.GetRobotById(robotCfg.RobotId)
    local characterViewModel = entity:GetCharacterViewModel()
    self.RImgHeadIcon:SetRawImage(characterViewModel:GetSmallHeadIcon())

    -- 是否解锁这个角色
    self.IsUnlock = XDataCenter.Maverick2Manager.IsRobotUnlock(robotCfg.RobotId)

    -- 未解锁和禁用显示
    self.RImgHeadIcon.gameObject:SetActiveEx(self.IsUnlock)
    self.RImgUnGet.gameObject:SetActiveEx(not self.IsUnlock)
    self.RImgForbid.gameObject:SetActiveEx(self.IsForbid)

    -- 选中
    self:ShowSelect(isSelect)
    if isSelect then
        self:OnClickRobot()
    end

    -- 红点
    local isRed = XDataCenter.Maverick2Manager.IsRobotRed(robotCfg.RobotId)
    self:ShowRed(isRed)
end

function XUiMaverick2CharacterRobot:OnClickRobot()
    self:ShowRed(false)
    XDataCenter.Maverick2Manager.RemoveRobotRed(self.RobotCfg.RobotId)
end

function XUiMaverick2CharacterRobot:ShowSelect(isSelect)
    self.PanelSelected.gameObject:SetActiveEx(isSelect)
end

function XUiMaverick2CharacterRobot:ShowRed(isRed)
    self.ImgRedPoint.gameObject:SetActiveEx(isRed)
end

return XUiMaverick2CharacterRobot