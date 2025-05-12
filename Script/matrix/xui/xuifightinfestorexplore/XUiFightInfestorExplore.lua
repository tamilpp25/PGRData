local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiFightInfestorExplore = XLuaUiManager.Register(XLuaUi, "UiFightInfestorExplore")
local XUiGridFightInfestorRuler = require("XUi/XUiFightInfestorExplore/XUiGridFightInfestorRuler")
local XUiGridFightInfestorPlayer = require("XUi/XUiFightInfestorExplore/XUiGridFightInfestorPlayer")

local DYNAMIC_DELEGATE_EVENT = DYNAMIC_DELEGATE_EVENT
local table = table
local math = math
local Vector3 = CS.UnityEngine.Vector3


function XUiFightInfestorExplore:OnAwake()
    self:InitComponent()
end

function XUiFightInfestorExplore:InitComponent()
    self.BrokePlayerIndexList = {}
    self.PlayerItemList = {}
    self.RemoveItemList = {}
    self.PlayerItem.gameObject:SetActiveEx(false)

    self.ScrollViewHeight = self.ScrollViewList.rect.height
    self.RulerHeight = self.Ruler.sizeDelta.y

    self.DynamicTable = XDynamicTableNormal.New(self.ScrollViewList.gameObject)
    self.DynamicTable:SetProxy(XUiGridFightInfestorRuler)
    self.DynamicTable:SetDelegate(self)
    local playerLayerPos = self.PlayerLayer.transform.localPosition
    self.PlayerLayer.transform.localPosition  = Vector3(playerLayerPos.x, 0, playerLayerPos.z)

    self.PanelEffect.gameObject:SetActive(false)
    self.PanelEffectLoader:SetLoadedCallback(function() self:OnEffectLoaded() end)
end

function XUiFightInfestorExplore:OnEnable()
    self:RefreshView()
end

function XUiFightInfestorExplore:OnDisable()
    self:RemoveTimer()
end

function XUiFightInfestorExplore:OnDestroy()
    self:RemoveTimer()
end

function XUiFightInfestorExplore:OnGetEvents()
    return { XEventId.EVENT_FIGHT_INFESTOR_SCORE_CHANGE}
end

function XUiFightInfestorExplore:OnNotify(evt)
    if evt == XEventId.EVENT_FIGHT_INFESTOR_SCORE_CHANGE then
        self:UpdateScrollViewOffset()
    end
end

function XUiFightInfestorExplore:AddTimer()
    self:RemoveTimer()
    self.scheduleId = XScheduleManager.ScheduleForever(function()
        self:CheckRemoveItemList()
        local lastScore = self.Score
        self.Score = XDataCenter.FightInfestorExploreManager.CalcScore(self.Score)
        if lastScore ~= self.Score then
            XDataCenter.FightInfestorExploreManager.SetScore(self.Score)
            self:UpdateScrollViewOffset(self.Score)
            self:RefreshScoreText()
        end
    end, XDataCenter.FightInfestorExploreManager.COLLECT_SCORE_TIME)
end

function XUiFightInfestorExplore:RemoveTimer()
    if self.scheduleId then
        XScheduleManager.UnSchedule(self.scheduleId)
        self.scheduleId = nil
    end
end

--动态列表事件
function XUiFightInfestorExplore:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT or event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local topNum = self.ListDataRuler[index]
        grid:Refresh(topNum)

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:OnListLoaded()
    end
end

function XUiFightInfestorExplore:RefreshView()
    self.Score = XDataCenter.FightInfestorExploreManager.GetScore()
    self.ScoreFloor = XDataCenter.FightInfestorExploreManager.GetScoreFloor(self.Score)
    self.ScoreGap = XDataCenter.FightInfestorExploreManager.GetScoreGap()

    self:RefreshScoreText()
    self.ListDataPlayer = XDataCenter.FightInfestorExploreManager.GetPlayerList()
    self.ListDataRuler = XDataCenter.FightInfestorExploreManager.GetRulerList(self.ListDataPlayer)
    self.TotalRulerHeight = self.RulerHeight * #self.ListDataRuler

    self.DynamicTable:SetDataSource(self.ListDataRuler)
    self.DynamicTable:ReloadDataASync()

    self:AddTimer()
end

function XUiFightInfestorExplore:OnListLoaded()
    self.DynamicTable:Freeze()
    self.PlayerLayerSize = self.PanelContent.sizeDelta
    self.PlayerLayer.sizeDelta = self.PlayerLayerSize
    self:RefreshPlayerList()

    self:UpdateScrollViewOffset(self.Score)
end

function XUiFightInfestorExplore:RefreshScoreText()
    self.TextSelfNum.text = XDataCenter.FightInfestorExploreManager.GetScoreStr(self.Score)
end

-- 设置列表偏移
function XUiFightInfestorExplore:UpdateScrollViewOffset(score)
    self.PosRate = (score - self.ScoreFloor) / self.ScoreGap
    local offsetY = self.PosRate * self.RulerHeight
    local normalizedPosition = offsetY / self.TotalRulerHeight
    if normalizedPosition > 1 or normalizedPosition < 0 then
        XLog.Error("列表位置超出范围 normalizedPosition:" .. tostring(normalizedPosition))
    end
    -- XLog.Debug(" normalizedPosition  " .. tostring(normalizedPosition) .. ", olde =" .. tostring(self.ScrollRect.verticalNormalizedPosition))
    self.ScrollRect.verticalNormalizedPosition = math.max(0, math.min(1, normalizedPosition))

    self:CheckPlayerBroken()
end


-- 设置列表偏移
function XUiFightInfestorExplore:GetPosYByScore(score)
    local offsetY = (score - self.ScoreFloor) / self.ScoreGap * self.RulerHeight
    local originY = self.TotalRulerHeight - self.ScrollViewHeight
    if originY < 0 then
        originY = 0
        XLog.Error("刻度数量过少，不足一页: " .. tostring(#self.ListDataRuler) .. "/" .. tostring(math.ceil(self.ScrollViewHeight / self.RulerHeight)))
    end
    local posY = originY - offsetY
    return posY
end

function XUiFightInfestorExplore:GetPlayerItem(index)
    local item = self.PlayerItemList[index]
    if not item then
        local go = CS.UnityEngine.Object.Instantiate(self.PlayerItem)
        go.transform:SetParent(self.PlayerLayer, false)
        item = XUiGridFightInfestorPlayer.New(self, go)
        self.PlayerItemList[index] = item
    end
    return item
end

function XUiFightInfestorExplore:ResetPlayerItemAll(len)
    if #self.PlayerItemList > len then
        for i = len + 1, #self.PlayerItemList do
            self.PlayerItemList[i].gameObject:SetActiveEx(false)
        end
    end
end

-- 创建玩家头像
function XUiFightInfestorExplore:RefreshPlayerList()
    local list = self.ListDataPlayer
    self:ResetPlayerItemAll(#list)
    for i, data in ipairs(list) do
        local item = self:GetPlayerItem(i)
        local posY = data:GetPosRate() * self.RulerHeight - self.PlayerLayerSize.y
        item.Transform.localPosition = Vector3(item.Transform.localPosition.x, posY)
        item.GameObject:SetActiveEx(true)
        item:Refresh(data)
    end
    return (#list > 0)
end

function XUiFightInfestorExplore:CheckPlayerBroken()
    local list = self.ListDataPlayer
    local posY
    for index = #list, 1, -1 do
        local data = list[index]
        if data:GetScore() <= self.Score then
            table.remove(list, index)
            local item = self.PlayerItemList[index]
            if item then
                if not posY then
                    posY = self:GetPosYByScore(self.Score)
                end
                item.Transform.localPosition = Vector3(item.Transform.localPosition.x, -self.RulerHeight)
                table.insert(self.BrokePlayerIndexList, index)
            else
                XLog.Error("消失的同组玩家不存在 i:" .. tostring(index))
            end
        end
    end
    self:DoPlayerBroken()
end
    
function XUiFightInfestorExplore:DoPlayerBroken()
    if #self.BrokePlayerIndexList == 0 then
        return 
    end
    self.PanelEffect.gameObject:SetActive(false)
    self.PanelEffect.gameObject:SetActive(true)

    local index = self.BrokePlayerIndexList[1]
    local item = self.PlayerItemList[index]
    local rawImage = item:GetRawImage()
    if self:PlayEffect(rawImage) then
        table.remove(self.PlayerItemList, index)
        table.remove(self.BrokePlayerIndexList, 1)
        table.insert(self.RemoveItemList, item)
    end
end

function XUiFightInfestorExplore:OnEffectLoaded()
    local go = self.PanelEffect.gameObject:FindGameObject("01")
    self.EffectRenderer = go:GetComponent("Renderer")
    self:DoPlayerBroken()
end

function XUiFightInfestorExplore:PlayEffect(rawImage)
    if XTool.UObjIsNil(rawImage) or XTool.UObjIsNil(rawImage.texture) then
        return true
    end
    if not self.EffectRenderer then
        return false
    end
    self.EffectRenderer.sharedMaterial:SetTexture("_MainTex", rawImage.texture)
    return true
end

function XUiFightInfestorExplore:CheckRemoveItemList()
    if #self.RemoveItemList > 0 then
        local item = table.remove(self.RemoveItemList, 1)
        if item and not XTool.UObjIsNil(item.GameObject) then
            CS.UnityEngine.Object.Destroy(item.GameObject)
        end
    end
end