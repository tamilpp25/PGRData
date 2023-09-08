local XUiPanelExpBar = require("XUi/XUiSettleWinMainLine/XUiPanelExpBar")

---@class XUiGridSettleWinRole
XUiGridWinRole = XClass(nil, "XUiGridWinRole")

function XUiGridWinRole:Ctor(rootUi, ui)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

-- 角色经验
function XUiGridWinRole:UpdateRoleInfo(charExpData, addExp)
    local charId = charExpData.Id
    local isRobot = XRobotManager.CheckIsRobotId(charId)
    local char
    if isRobot then
        self:UpdateRobotInfo(charId)
        return
    else
        char = XDataCenter.CharacterManager.GetCharacter(charId)
    end

    if char == nil then
        return
    end

    local lastLevel = charExpData.Level
    local lastExp = charExpData.Exp
    local lastMaxExp = XMVCA.XCharacter:GetNextLevelExp(charId, lastLevel)
    local curLevel = char.Level
    local curExp = char.Exp
    local curMaxExp = XMVCA.XCharacter:GetNextLevelExp(charId, curLevel)
    self.PlayerExpBar = self.PlayerExpBar or XUiPanelExpBar.New(self.PanelPlayerExpBar)
    self.PlayerExpBar:LetsRoll(lastLevel, lastExp, lastMaxExp, curLevel, curExp, curMaxExp, addExp)
    self.PlayerExpBar:SetShareTag(false)

    local icon = XDataCenter.CharacterManager.GetCharBigHeadIcon(charId)
    if icon then
        self.RImgIcon:SetRawImage(icon)
    end
end

-- 机器人
function XUiGridWinRole:UpdateRobotInfo(robotId)
    local data = XRobotManager.GetRobotTemplate(robotId)
    local curLevel = data.CharacterLevel
    local curExp = 1
    local maxExp = 1
    local addExp = 0
    self.PlayerExpBar = self.PlayerExpBar or XUiPanelExpBar.New(self.PanelPlayerExpBar)
    self.PlayerExpBar:LetsRoll(curLevel, curExp, maxExp, curLevel, curExp, maxExp, addExp)
    self.PlayerExpBar:SetShareTag(false)

    local icon = XDataCenter.CharacterManager.GetCharBigHeadIcon(data.CharacterId)
    if icon then
        self.RImgIcon:SetRawImage(icon)
    end
end

-- 共享的角色
function XUiGridWinRole:UpdateShareRoleInfo(shareRoleInfo)
    local charId = shareRoleInfo.Id
    local lastLevel = shareRoleInfo.Level
    local lastExp = shareRoleInfo.Exp
    local lastMaxExp = XMVCA.XCharacter:GetNextLevelExp(charId, lastLevel)
    local curLevel = shareRoleInfo.Level
    local curExp = shareRoleInfo.Exp
    local curMaxExp = XMVCA.XCharacter:GetNextLevelExp(charId, curLevel)

    self.PlayerExpBar = self.PlayerExpBar or XUiPanelExpBar.New(self.PanelPlayerExpBar)
    self.PlayerExpBar:LetsRoll(lastLevel, lastExp, lastMaxExp, curLevel, curExp, curMaxExp, 0)
    self.PlayerExpBar:SetShareTag(true)

    local icon = XDataCenter.CharacterManager.GetCharBigHeadIcon(charId)
    if icon then
        self.RImgIcon:SetRawImage(icon)
    end
end

-- 机器人
function XUiGridWinRole:UpdateNieRRobotInfo(robotId)
    local data = XRobotManager.TryGetRobotTemplate(robotId)
    local curLevel = data.CharacterLevel
    local curExp = 1
    local maxExp = 1
    local addExp = 0
    self.PlayerExpBar = self.PlayerExpBar or XUiPanelExpBar.New(self.PanelPlayerExpBar)
    self.PlayerExpBar:LetsRoll(curLevel, curExp, maxExp, curLevel, curExp, maxExp, addExp)
    self.PlayerExpBar:SetShareTag(false)

    
    local icon
    local nierCharacterId = XDataCenter.NieRManager.GetCharacterIdByNieRRobotId(robotId)
    if nierCharacterId ~= 0 then
        local nierCharacter = XDataCenter.NieRManager.GetNieRCharacterByCharacterId(nierCharacterId)
        icon = XDataCenter.FashionManager.GetFashionBigHeadIcon(nierCharacter:GetNieRFashionId())
    else
        icon = XDataCenter.CharacterManager.GetCharBigHeadIcon(data.CharacterId)
    end
    
    if icon then
        self.RImgIcon:SetRawImage(icon)
    end
end

function XUiGridWinRole:UpdateTaikoRoleInfo(robotId)
    self.PanelPlayerExpBar.gameObject:SetActiveEx(false)
    local icon = XCharacterCuteConfig.GetCuteModelSmallHeadIcon(XRobotManager.GetCharacterId(robotId))
    if icon then
        self.RImgIcon:SetRawImage(icon)
    end
end