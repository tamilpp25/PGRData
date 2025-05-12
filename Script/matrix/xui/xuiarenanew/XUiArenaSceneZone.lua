local XUiArenaScenePlayerGrid = require("XUi/XUiArenaNew/XUiArenaScenePlayerGrid")

---@class XUiArenaSceneZone
local XUiArenaSceneZone = XClass(nil, "XUiArenaSceneZone")

function XUiArenaSceneZone:Ctor(zoneObject, stageObject)
    self:Init(zoneObject, stageObject)
end

function XUiArenaSceneZone:Init(zoneObject, stageObject)
    local rankRoot = zoneObject.transform:FindTransform("ListRank")
    local gridPlayer = zoneObject.transform:FindTransform("GridPlayer")
    local playerList = {}

    for i = 1, 3 do
        local gridPlayerObject = XUiHelper.Instantiate(gridPlayer, rankRoot)

        playerList[i] = XUiArenaScenePlayerGrid.New(gridPlayerObject)
    end

    gridPlayer.gameObject:SetActiveEx(false)
    stageObject.gameObject:SetActiveEx(true)
    zoneObject.gameObject:SetActiveEx(true)

    self._EnterEffect = stageObject.transform:FindTransform("FxUiArenaNewStar01")
    self._FinishEnterEffect = stageObject.transform:FindTransform("FxUiArenaNewLoop02")
    self._ChangeEffect = stageObject.transform:FindTransform("FxUiArenaNewStar02")
    self._Normal = stageObject.transform:FindTransform("Normal")
    self._Select = stageObject.transform:FindTransform("Select")
    self._Finish = stageObject.transform:FindTransform("Finish")
    self._LinkEnableAnimation = zoneObject.transform:FindTransform("PanelPiontEnable")
    self._StartAnimation = zoneObject.transform:FindTransform("NameStart")
    self._Button = zoneObject:GetComponent(typeof(CS.XUiComponent.XUiButton))
    self._StageObject = stageObject
    self._CurrentState = "Normal"
    self._PlayerGridRoot = rankRoot
    ---@type XUiArenaScenePlayerGrid[]
    self._PlayerGridList = playerList

    self:SetEnterEffectActive(false)
    self:SetChangeEffectActive(false)
    self:SetPlayerListActive(false)
end

function XUiArenaSceneZone:SetCurrentState(value)
    self._CurrentState = value
    self:RecoveryState()
end

function XUiArenaSceneZone:ChangeState(state)
    if self._Normal and self._Select and self._Finish then
        if state == "Normal" then
            self._Normal.gameObject:SetActiveEx(true)
            self._Select.gameObject:SetActiveEx(false)
            self._Finish.gameObject:SetActiveEx(false)
        elseif state == "Select" then
            self._Select.gameObject:SetActiveEx(true)
        elseif state == "Finish" then
            self._Normal.gameObject:SetActiveEx(false)
            self._Select.gameObject:SetActiveEx(false)
            self._Finish.gameObject:SetActiveEx(true)
        end
    end
end

function XUiArenaSceneZone:RecoveryState()
    self:ChangeState(self._CurrentState)
end

function XUiArenaSceneZone:SetTextByIndex(index, text)
    self._Button:SetNameByGroup(index, text)
end

function XUiArenaSceneZone:SetTextActiveByIndex(index, isActive)
    self._Button:ActiveTextByGroup(index, isActive)
end

function XUiArenaSceneZone:ShowTag(isShow)
    self._Button:ShowTag(isShow)
end

function XUiArenaSceneZone:ShowPoint(isShow)
    self._Button:ShowReddot(isShow)
end

function XUiArenaSceneZone:SetClickEvent(clickEvent)
    self._Button.CallBack = clickEvent
end

function XUiArenaSceneZone:SetActive(isActive)
    self._Button.gameObject:SetActiveEx(isActive)
    self._StageObject.gameObject:SetActiveEx(isActive)
end

function XUiArenaSceneZone:SetPlayerListActive(isActive)
    self._PlayerGridRoot.gameObject:SetActiveEx(isActive)
    if isActive then
        self:PlayRankAnimation()
    end
end

function XUiArenaSceneZone:SetEnterEffectActive(isActive)
    if self._EnterEffect then
        self._EnterEffect.gameObject:SetActiveEx(isActive)
    end
    if self._FinishEnterEffect then
        self._FinishEnterEffect.gameObject:SetActiveEx(isActive)
    end
end

function XUiArenaSceneZone:SetChangeEffectActive(isActive)
    if self._ChangeEffect then
        self._ChangeEffect.gameObject:SetActiveEx(isActive)
    end
end

function XUiArenaSceneZone:PlayRankAnimation()
    self:PlayeLinkAnimation()
    self:PlayPlayerGridAnimation()
end

function XUiArenaSceneZone:PlayeLinkAnimation()
    if self._LinkEnableAnimation then
        self._LinkEnableAnimation:PlayTimelineAnimation()
    end
end

function XUiArenaSceneZone:PlayeStartAnimation()
    if self._StartAnimation then
        self._StartAnimation:PlayTimelineAnimation()
    end
end

function XUiArenaSceneZone:PlayPlayerGridAnimation()
    if not XTool.IsTableEmpty(self._PlayerGridList) then
        for i, playerGrid in pairs(self._PlayerGridList) do
            playerGrid:AlphaHide()
        end

        RunAsyn(function()
            for i, playerGrid in pairs(self._PlayerGridList) do
                playerGrid:PlayAnimation()
                asynWaitSecond(0.05)
            end
        end)
    end
end

---@param areaShowData XArenaAreaShowData
function XUiArenaSceneZone:RefreshPlayerGrid(areaShowData)
    if areaShowData and not areaShowData:IsClear() then
        for i, playerGrid in pairs(self._PlayerGridList) do
            playerGrid:Refresh(areaShowData:GetLordPlayerDataByIndex(i), i)
        end
    end
end

return XUiArenaSceneZone
