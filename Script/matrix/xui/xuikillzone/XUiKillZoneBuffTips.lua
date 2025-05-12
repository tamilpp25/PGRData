local CsXTextManagerGetText = CsXTextManagerGetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiKillZoneBuffTips = XLuaUiManager.Register(XLuaUi, "UiKillZoneBuffTips")

function XUiKillZoneBuffTips:OnAwake()
    self:AutoAddListener()
    self.GridBuff.gameObject:SetActiveEx(false)
end

function XUiKillZoneBuffTips:OnStart(stageId)
    self.StageId = stageId
    self.BuffGrids = {}
end

function XUiKillZoneBuffTips:OnEnable()
    self:UpdateView()
end

function XUiKillZoneBuffTips:UpdateView()
    local buffIds = XDataCenter.KillZoneManager.GetStageBuffIds(self.StageId)
    for index, buffId in ipairs(buffIds) do
        local grid = self.BuffGrids[index]
        if not grid then
            local go = index == 1 and self.GridBuff or CSUnityEngineObjectInstantiate(self.GridBuff, self.PanelContent)
            grid = XTool.InitUiObjectByUi({}, go)
            self.BuffGrids[index] = grid
        end

        local icon = XKillZoneConfigs.GetBuffIcon(buffId)
        grid.RImgIcon:SetRawImage(icon)

        local name = XKillZoneConfigs.GetBuffName(buffId)
        grid.TxtName.text = name

        local desc = XKillZoneConfigs.GetBuffDesc(buffId)
        grid.TxtDesc.text = desc

        grid.GameObject:SetActiveEx(true)
    end
    for index = #buffIds + 1, #self.BuffGrids do
        self.BuffGrids[index].GameObject:SetActiveEx(false)
    end
end

function XUiKillZoneBuffTips:AutoAddListener()
    self.BtnTanchuangCloseBig.CallBack = function() self:Close() end
end