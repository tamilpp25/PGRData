local XUiGridAreaWarHangUp = require("XUi/XUiAreaWar/XUiGridAreaWarHangUp")

local XUiAreaWarHangUp = XLuaUiManager.Register(XLuaUi, "UiAreaWarHangUp")

function XUiAreaWarHangUp:OnAwake()
    self.GridCourse.gameObject:SetActiveEx(false)
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    XDataCenter.ItemManager.AddCountUpdateListener(
        {
            XDataCenter.ItemManager.ItemId.AreaWarCoin,
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        },
        handler(self, self.UpdateAssets),
        self.AssetActivityPanel
    )
    self:AutoAddListener()
end

function XUiAreaWarHangUp:OnStart()
    self.GridList = {}
    self:InitView()
end

function XUiAreaWarHangUp:OnEnable()
    if self.IsEnd then
        return
    end
    if XDataCenter.AreaWarManager.OnActivityEnd() then
        self.IsEnd = true
        return
    end

    self:UpdateAssets()
    self:UpdateView()
end

function XUiAreaWarHangUp:OnGetEvents()
    return {
        XEventId.EVENT_AREA_WAR_HANG_UP_REWARD_REMIND_CHANGE,
        XEventId.EVENT_AREA_WAR_HANG_UP_REWARD_COUNT_CHANGE,
        XEventId.EVENT_AREA_WAR_ACTIVITY_END
    }
end

function XUiAreaWarHangUp:OnNotify(evt, ...)
    if self.IsEnd then
        return
    end

    local args = {...}
    if evt == XEventId.EVENT_AREA_WAR_HANG_UP_REWARD_REMIND_CHANGE then
        XDataCenter.AreaWarManager.AreaWarOpenHangUpRequest()
    elseif evt == XEventId.EVENT_AREA_WAR_HANG_UP_REWARD_COUNT_CHANGE then
        self:UpdateView()
    elseif evt == XEventId.EVENT_AREA_WAR_ACTIVITY_END then
        if XDataCenter.AreaWarManager.OnActivityEnd() then
            self.IsEnd = true
            return
        end
    end
end

function XUiAreaWarHangUp:AutoAddListener()
    self:BindHelpBtn(self.BtnHelp, "AreaWarHangUp")
    self.BtnBack.CallBack = function()
        self:Close()
    end
    self.BtnMainUi.CallBack = function()
        XLuaUiManager.RunMain()
    end
    self.BtnGet.CallBack = function()
        self:OnClickBtnGet()
    end
end

function XUiAreaWarHangUp:InitView()
    self.TxtTips.text = CsXTextManagerGetText("AreaWarHangUpTips")
    self.RImgIcon:SetRawImage(XDataCenter.AreaWarManager.GetCoinItemIcon())

    --挂机等级
    local hangUpLv = XDataCenter.AreaWarManager.GetHangUpLevel()
    self.TxtHangupLv.text = hangUpLv

    local ids = XAreaWarConfigs.GetAllHangUpIds()
    local totalLevel = #ids
    self.ImgFillAmount.fillAmount = totalLevel ~= 0 and hangUpLv / totalLevel or 1

    for index, id in ipairs(ids) do
        local grid = self.GridList[index]
        if not grid then
            local go = index == 1 and self.GridCourse or CSObjectInstantiate(self.GridCourse, self.PanelCourseContainer)
            grid = XUiGridAreaWarHangUp.New(go)
            self.GridList[index] = grid
        end

        grid:Refresh(id, hangUpLv)
        grid.GameObject:SetActiveEx(true)
    end
    for index = #ids + 1, #self.GridList do
        self.GridList[index].GameObject:SetActiveEx(false)
    end
end

function XUiAreaWarHangUp:UpdateAssets()
    self.AssetActivityPanel:Refresh(
        {
            XDataCenter.ItemManager.ItemId.AreaWarCoin,
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        },
        {
            XDataCenter.ItemManager.ItemId.AreaWarActionPoint
        }
    )
end

function XUiAreaWarHangUp:UpdateView()
    --可领取数量
    local itemCount = XDataCenter.AreaWarManager.GetHangUpRewardCount()
    self.TxtCount.text = itemCount

    local canGet = itemCount > 0
    self.BtnGet:SetDisable(not canGet)
end

function XUiAreaWarHangUp:OnClickBtnGet()
    if not XDataCenter.AreaWarManager.HasHangUpRewardToGet() then
        return
    end
    XDataCenter.AreaWarManager.AreaWarGetHangUpRewardRequest(
        function(rewardGoodsList)
            if not XTool.IsTableEmpty(rewardGoodsList) then
                XUiManager.OpenUiObtain(rewardGoodsList)
            end
        end
    )
end
