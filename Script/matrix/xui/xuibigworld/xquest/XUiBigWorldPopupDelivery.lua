

---@class XUiBigWorldPopupDelivery : XLuaUi
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _Control XBigWorldQuestControl
local XUiBigWorldPopupDelivery = XLuaUiManager.Register(XLuaUi, "UiBigWorldPopupDelivery")

local XUiSGPanelDelivery = require("XUi/XUiBigWorld/XQuest/Panel/XUiPanelBWDelivery")

function XUiBigWorldPopupDelivery:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBigWorldPopupDelivery:OnStart(objectiveId)
    self._ObjId = objectiveId
    self:InitView()
end

function XUiBigWorldPopupDelivery:InitUi()
    self._PanelNeed = XUiSGPanelDelivery.New(self.PanelNeed, self)
    self._PanelWarehouse = XUiSGPanelDelivery.New(self.PanelItem, self, nil, true)

    --默认不选中，需要玩家手动点击
    self.BtnConfirm:SetDisable(true, false)
end

function XUiBigWorldPopupDelivery:InitCb()
    self.BtnClose.CallBack = function()
        self:Close()
    end

    self.BtnCancel.CallBack = function()
        self:Close()
    end

    self.BtnConfirm.CallBack = function()
        self:OnBtnConfirmClick()
    end
end

function XUiBigWorldPopupDelivery:InitView()
    self:CalConsume()

    self._PanelNeed:RefreshView(self._DataNeed)
    self._PanelWarehouse:RefreshView(self._DataWarehouse)
end

function XUiBigWorldPopupDelivery:OnBtnConfirmClick()
    if XTool.IsTableEmpty(self._DataNeed) then
        return
    end

    self:Close()
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_QUEST_ITEMS_DELIVERY_CONFIRM)
end

function XUiBigWorldPopupDelivery:CalConsume()
    local consume = self._Control:GetObjectConsume(self._ObjId)
    if XTool.IsTableEmpty(consume) then
        return
    end
    local dataNeed, dataWarehouse = {}, {}
    for id, count in pairs(consume) do
        local exist = XMVCA.XBigWorldService:IsQuestItemExist(id)
        dataNeed[#dataNeed + 1] = {
            Id = id,
            Total = count,
            Select = 0
        }

        if exist then
            dataWarehouse[#dataWarehouse + 1] = {
                Id = id,
                Total = XMVCA.XBigWorldService:GetQuestItemCount(id),
                Select = 0
            }
        end
    end

    self._DataNeed = dataNeed
    self._DataWarehouse = dataWarehouse
end

function XUiBigWorldPopupDelivery:OnSelectItemInWarehouse(itemId)
    local select = 0
    local disable = false
    local ownCount = XMVCA.XBigWorldService:GetQuestItemCount(itemId)
    for _, data in pairs(self._DataNeed) do
        if data.Id == itemId then
            select = math.min(ownCount, data.Total)
            data.Select = select
        end

        if data.Select < data.Total then
            disable = true
        end
    end

    for _, data in pairs(self._DataWarehouse) do
        if data.Id == itemId then
            data.Select = select
        end
    end

    self._PanelNeed:RefreshView(self._DataNeed)
    self._PanelWarehouse:RefreshView(self._DataWarehouse)

    self.BtnConfirm:SetDisable(disable, not disable)
end