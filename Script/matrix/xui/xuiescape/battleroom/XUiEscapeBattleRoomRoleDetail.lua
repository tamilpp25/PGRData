--######################## XUiEscapeBattleRoomChildPanel ########################
local XUiEscapeBattleRoomChildPanel = XClass(nil, "XUiEscapeBattleRoomChildPanel")

function XUiEscapeBattleRoomChildPanel:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.IsInitRegisterUiEvents = true
end

function XUiEscapeBattleRoomChildPanel:SetData(team, stageId, entityId, rootUi)
    self:RegisterUiEvents(rootUi)

end

function XUiEscapeBattleRoomChildPanel:RegisterUiEvents(rootUi)
    if not self.IsInitRegisterUiEvents then
        return
    end

    -- 角色类型按钮组
    rootUi.BtnGroupCharacterType:Init(
        {
            [XCharacterConfigs.CharacterType.Normal] = rootUi.BtnTabGouzaoti,
            [XCharacterConfigs.CharacterType.Isomer] = rootUi.BtnTabShougezhe,
            [XCharacterConfigs.CharacterType.Robot] = self.BtnTabRobot,
        },
        function(tabIndex)
            rootUi:OnBtnGroupCharacterTypeClicked(tabIndex)
        end
    )

    self.BtnFilter.CallBack = function()
        rootUi:OnBtnFilterClicked()
    end

    self.IsInitRegisterUiEvents = false
end

--######################## XUiEscapeBattleRoomRoleDetail ########################
local XRobot = require("XEntity/XRobot/XRobot")
local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
local XUiEscapeBattleRoomRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiEscapeBattleRoomRoleDetail")

function XUiEscapeBattleRoomRoleDetail:Ctor()
    self.RobotEntities = {}
    local robotIdList = XFubenConfigs.GetStageTypeRobot(XDataCenter.FubenManager.StageType.Escape)
    for _, robotId in ipairs(robotIdList) do
        table.insert(self.RobotEntities, XRobot.New(robotId))
    end
end

function XUiEscapeBattleRoomRoleDetail:GetChildPanelData()
    if self.ChildPanelData == nil then
        self.ChildPanelData = {
            assetPath = XUiConfigs.GetComponentUrl("UiPanelEscapeBattleRoomRoleDetail"),
            proxy = XUiEscapeBattleRoomChildPanel,
            proxyArgs = { "Team", "StageId", "CurrentEntityId", self.RootUi }
        }
    end
    return self.ChildPanelData
end

function XUiEscapeBattleRoomRoleDetail:GetEntities(characterType)
    if XCharacterConfigs.CharacterType.Robot ~= characterType then
        return self.Super.GetEntities(self, characterType)
    end
    return self.RobotEntities
end

function XUiEscapeBattleRoomRoleDetail:GetAutoCloseInfo()
    local callback = function(isClose)
        if isClose then
            XDataCenter.EscapeManager.HandleActivityEndTime()
        end
    end
    return true, XDataCenter.EscapeManager.GetActivityEndTime(), callback
end

function XUiEscapeBattleRoomRoleDetail:AOPOnStartBefore(rootUi)
    self.RootUi = rootUi
end

function XUiEscapeBattleRoomRoleDetail:AOPOnStartAfter(rootUi)
    rootUi.BtnFilter.gameObject:SetActiveEx(false)
    rootUi.CurrentSelectTagGroup = {
        [XCharacterConfigs.CharacterType.Normal] = {},
        [XCharacterConfigs.CharacterType.Isomer] = {},
        [XCharacterConfigs.CharacterType.Robot] = {},
    }
    if XEntityHelper.GetIsRobot(rootUi.CurrentEntityId) then
        rootUi.CurrentCharacterType = XCharacterConfigs.CharacterType.Robot
    end
end

return XUiEscapeBattleRoomRoleDetail