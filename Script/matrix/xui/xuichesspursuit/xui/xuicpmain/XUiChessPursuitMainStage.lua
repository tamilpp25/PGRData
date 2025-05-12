local XChessPursuitCtrl = require("XUi/XUiChessPursuit/XChessPursuitCtrl")
local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiChessPursuitMainBase = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XUiChessPursuitMainBase")
local XUiChessPursuitMainStage = XClass(XUiChessPursuitMainBase, "XUiChessPursuitMainStage")
local XUiChessPursuitStageGrid = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XUiChessPursuitStageGrid")
local XUiChessPursuitPanelFightStage = require("XUi/XUiChessPursuit/XUi/XUiCPMain/XUiChessPursuitPanelFightStage")
local CSXTextManagerGetText = CS.XTextManager.GetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

function XUiChessPursuitMainStage:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.UiChessPursuitStageGrid = {}

    XTool.InitUiObject(self)
    self:AutoAddListener()
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiChessPursuitMainStage:Dispose()
    self.GameObject:SetActiveEx(false)
    for i,uiChessPursuitStageGrid in pairs(self.UiChessPursuitStageGrid) do
        uiChessPursuitStageGrid:Dispose()
    end

    self.UiChessPursuitStageGrid = {}
end

function XUiChessPursuitMainStage:Init(params, callBack)
    XUiChessPursuitMainStage.Super.Init(self, params)
    self.GameObject:SetActiveEx(true)
    self.RootUi:PlayAnimationWithMask("PanelStage")

    self:Update()
    if callBack then
        callBack()
    end
end

--@region 事件绑定

function XUiChessPursuitMainStage:AutoAddListener()
    XUiHelper.RegisterClickEvent(self, self.BtnRank, self.OnBtnRankClick)
    XUiHelper.RegisterClickEvent(self, self.BtnChessPursuitItem, self.OnBtnChessPursuitItemClick)
    XUiHelper.RegisterClickEvent(self, self.BtnStage2, self.OnBtnBtnStage2Click)
    XUiHelper.RegisterClickEvent(self, self.BtnHard, self.OnBtnHardClick)
    XUiHelper.RegisterClickEvent(self, self.BtnDefault, self.OnBtnDefaultClick)
    XUiHelper.RegisterClickEvent(self, self.BtnStage3, self.OnBtnBtnStage3Click)
end

function XUiChessPursuitMainStage:OnBtnBtnStage2Click()
    local cfg = XChessPursuitConfig.GetChessPursuitMapByUiType(XChessPursuitCtrl.MAIN_UI_TYPE.FIGHT_DEFAULT)
    if not cfg then
        return
    end
    XSaveTool.SaveData(self.RootUi:GetSaveToolKey(), cfg.Id)

    self.RootUi:SwtichUI(XChessPursuitCtrl.MAIN_UI_TYPE.SCENE, {
        MapId = cfg.Id
    })
end

function XUiChessPursuitMainStage:OnBtnBtnStage3Click()
    local cfg = XChessPursuitConfig.GetChessPursuitMapByUiType(XChessPursuitCtrl.MAIN_UI_TYPE.FIGHT_HARD)
    if not cfg then
        return
    end
    XSaveTool.SaveData(self.RootUi:GetSaveToolKey(), cfg.Id)

    self.RootUi:SwtichUI(XChessPursuitCtrl.MAIN_UI_TYPE.SCENE, {
        MapId = cfg.Id
    })
end

function XUiChessPursuitMainStage:OnBtnHardClick()
    local cfg = XChessPursuitConfig.GetChessPursuitMapByUiType(XChessPursuitCtrl.MAIN_UI_TYPE.FIGHT_HARD)
    
    self.RootUi.PanelMaskHeard.gameObject:SetActiveEx(true)
    self.RootUi:PlayAnimationWithMask("YellowQieHuan1", function ()
        self.RootUi:SwtichUI(XChessPursuitCtrl.MAIN_UI_TYPE.FIGHT_HARD, {
            MapId = cfg.Id,
            CallBack = function ()
                self.RootUi:PlayAnimationWithMask("YellowQieHuan2", function ()
                    self.RootUi.PanelMaskHeard.gameObject:SetActiveEx(false)
                end)
            end,
        })
    end)
end

function XUiChessPursuitMainStage:OnBtnDefaultClick()
    local cfg = XChessPursuitConfig.GetChessPursuitMapByUiType(XChessPursuitCtrl.MAIN_UI_TYPE.FIGHT_DEFAULT)

    self.RootUi.PanelMaskNormal.gameObject:SetActiveEx(true)
    self.RootUi:PlayAnimationWithMask("RedQieHuan1", function ()
        self.RootUi:SwtichUI(XChessPursuitCtrl.MAIN_UI_TYPE.FIGHT_DEFAULT, {
            MapId = cfg.Id,
            CallBack = function ()
                self.RootUi:PlayAnimationWithMask("RedQieHuan2", function ()
                    self.RootUi.PanelMaskNormal.gameObject:SetActiveEx(false)
                end)
            end,
        })
    end)
end

function XUiChessPursuitMainStage:OnBtnRankClick()
    XDataCenter.ChessPursuitManager.ChessPursuitGetRankRequest(function(groupId)
        XLuaUiManager.Open("UiChessPursuitRank", groupId)
    end)
end

function XUiChessPursuitMainStage:OnBtnChessPursuitItemClick()
    XDataCenter.ChessPursuitManager.OpenCoinTip()
end
--@endregion

function XUiChessPursuitMainStage:Update()
    self:UpdateActive()
    self:UpdateTitle()
    self:UpdateInfo()

    if self.UiType == XChessPursuitCtrl.MAIN_UI_TYPE.STABLE then
        self:UpdateStable()
    elseif self.UiType == XChessPursuitCtrl.MAIN_UI_TYPE.FIGHT_DEFAULT then
        self:UpdateFightDefault()
    elseif self.UiType == XChessPursuitCtrl.MAIN_UI_TYPE.FIGHT_HARD then
        self:UpdateFightHeard()
    end
end

function XUiChessPursuitMainStage:UpdateTitle()
    if self.UiType == XChessPursuitCtrl.MAIN_UI_TYPE.STABLE then
        self.TxtStageName.text = CSXTextManagerGetText("ChessPursuitStable")
    else
        self.TxtStageName.text = CSXTextManagerGetText("ChessPursuitFight")
    end

    local beginTime = XChessPursuitConfig.GetActivityBeginTime()
    local endTime = XChessPursuitConfig.GetActivityEndTime()
    local weekBeginDesc = XTime.TimestampToGameDateTimeString(beginTime, "HH:mm")
    local weekEndDesc = XTime.TimestampToGameDateTimeString(endTime, "HH:mm")
    local beginDay = self:GetWeekDayDesc(beginTime)
    local endDay = self:GetWeekDayDesc(endTime)

    self.TxtStageTime.text = CSXTextManagerGetText("ChessPursuitTimeDesc", beginDay..weekBeginDesc, endDay..weekEndDesc)
end

function XUiChessPursuitMainStage:UpdateInfo()
    local sum = XDataCenter.ChessPursuitManager.GetSumCoinCount()
    local itemName = XItemConfigs.GetItemNameById(XChessPursuitConfig.SHOP_COIN_ITEM_ID)
    local itemIcon = XItemConfigs.GetItemIconById(XChessPursuitConfig.SHOP_COIN_ITEM_ID)

    if self.UiType == XChessPursuitCtrl.MAIN_UI_TYPE.STABLE then
        self.TxtDescribe.text = CSXTextManagerGetText("ChessPursuitDrillItemCoinDesc", itemName)
    else
        self.TxtDescribe.text = CSXTextManagerGetText("ChessPursuitActualCombatItemCoinDesc", itemName)
    end
    self.TxtNumber.text = sum
    self.RImgIconCoin:SetRawImage(itemIcon)
end

function XUiChessPursuitMainStage:UpdateActive()
    self.PanelStage1.gameObject:SetActiveEx(self.UiType == XChessPursuitCtrl.MAIN_UI_TYPE.STABLE)
    self.PanelStage2.gameObject:SetActiveEx(self.UiType == XChessPursuitCtrl.MAIN_UI_TYPE.FIGHT_DEFAULT)
    self.PanelStage3.gameObject:SetActiveEx(self.UiType == XChessPursuitCtrl.MAIN_UI_TYPE.FIGHT_HARD)
    self.BtnRank.gameObject:SetActiveEx(self.UiType == XChessPursuitCtrl.MAIN_UI_TYPE.FIGHT_HARD or self.UiType == XChessPursuitCtrl.MAIN_UI_TYPE.FIGHT_DEFAULT)
    self.HistoryKillDetails.gameObject:SetActiveEx(self.UiType == XChessPursuitCtrl.MAIN_UI_TYPE.FIGHT_HARD or self.UiType == XChessPursuitCtrl.MAIN_UI_TYPE.FIGHT_DEFAULT)
end

function XUiChessPursuitMainStage:UpdateStable()
    local groupId = XChessPursuitConfig.GetCurrentGroupId()
    local mapsCfg = XChessPursuitConfig.GetChessPursuitMapsByGroupId(groupId)
    
    self.GridStage.gameObject:SetActiveEx(false)
    for _,cfg in ipairs(mapsCfg) do
        if not self.UiChessPursuitStageGrid[cfg.Id] then
            local grid = CSUnityEngineObjectInstantiate(self.GridStage, self.Content)
            self.UiChessPursuitStageGrid[cfg.Id] = XUiChessPursuitStageGrid.New(grid, self.RootUi, cfg.Id)
        end

        self.UiChessPursuitStageGrid[cfg.Id]:Refresh()
    end
end

function XUiChessPursuitMainStage:UpdateFightDefault()
    local cfg = XChessPursuitConfig.GetChessPursuitMapByUiType(XChessPursuitCtrl.MAIN_UI_TYPE.FIGHT_DEFAULT)
    local xUiChessPursuitPanelFightStage = XUiChessPursuitPanelFightStage.New(self.PanelStage2, self.RootUi, cfg.Id)
    local mapDb = XDataCenter.ChessPursuitManager.GetChessPursuitMapDb(cfg.Id)

    if mapDb:IsKill() then
        self.BtnHard.gameObject:SetActiveEx(self:IsOpenFightHeard())
        self.HistoryKillDetails.gameObject:SetActiveEx(true)
        local count = mapDb:GetWinForBattleCount()
        self.TxtHistoryKilDetailsCount.text = count
    else
        self.BtnHard.gameObject:SetActiveEx(false)
        self.HistoryKillDetails.gameObject:SetActiveEx(false)
    end
    xUiChessPursuitPanelFightStage:Refresh()
end

function XUiChessPursuitMainStage:UpdateFightHeard()
    local cfg = XChessPursuitConfig.GetChessPursuitMapByUiType(XChessPursuitCtrl.MAIN_UI_TYPE.FIGHT_HARD)
    local xUiChessPursuitPanelFightStage = XUiChessPursuitPanelFightStage.New(self.PanelStage3, self.RootUi, cfg.Id)

    xUiChessPursuitPanelFightStage:Refresh()
end

function XUiChessPursuitMainStage:IsOpenFightHeard()
    return XDataCenter.ChessPursuitManager.IsOpenFightHeard()
end

function XUiChessPursuitMainStage:GetWeekDayDesc(time)
    local weekDay = XTime.GetWeekDay(time, true)
    if weekDay == 1 then
        return CSXTextManagerGetText("Monday")
    elseif weekDay == 2 then
        return CSXTextManagerGetText("Tuesday")
    elseif weekDay == 3 then
        return CSXTextManagerGetText("Wednesday")
    elseif weekDay == 4 then
        return CSXTextManagerGetText("Thursday")
    elseif weekDay == 5 then
        return CSXTextManagerGetText("Friday")
    elseif weekDay == 6 then
        return CSXTextManagerGetText("Saturday")
    elseif weekDay == 7 then
        return CSXTextManagerGetText("Sunday")
    end
end

return XUiChessPursuitMainStage
