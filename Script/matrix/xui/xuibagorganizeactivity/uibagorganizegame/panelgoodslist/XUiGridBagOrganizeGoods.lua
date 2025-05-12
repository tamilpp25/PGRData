---@class XUiGridBagOrganizeGoods:XUiNode
---@field _Control XBagOrganizeActivityControl
---@field _GameControl XBagOrganizeActivityGameControl
local XUiGridBagOrganizeGoods = XClass(XUiNode, 'XUiGridBagOrganizeGoods')

function XUiGridBagOrganizeGoods:OnStart(clickCb)
    self._ClickCb = clickCb
    self.GridBtn.CallBack = handler(self, self.OnClickEvent)
    self._GameControl = self._Control:GetGameControl()
    self._GameControl:AddEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_TIMELIMIT_RULE_UPDATE, self.RefreshLifeTime, self)

    self.DragCom:AddBeginDragListener(handler(self, self.OnBeginDragEvent))
    self.DragCom:AddDragListener(handler(self, self.OnDragEvent))
    self.DragCom:AddEndDragListener(handler(self, self.OnEndDragEvent))
end

function XUiGridBagOrganizeGoods:OnEnable()
    
end

function XUiGridBagOrganizeGoods:OnDisable()
    self._Id = nil
end

function XUiGridBagOrganizeGoods:OnDestroy()
    self._GameControl:RemoveEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_TIMELIMIT_RULE_UPDATE, self.RefreshLifeTime, self)
end

function XUiGridBagOrganizeGoods:SetData(id)
    local goodsId = XMath.ToMinInt(math.fmod(id, 10000))
    local uid = XMath.ToMinInt(id / 10000)
    
    self._Id = id
    self._GoodsId = goodsId
    self._GoodsUid = uid
    self.GameObject.name = self._Id
    self:InitUI()
    self:RefreshUsingState()
    
    self:RefreshLifeTime()
end

function XUiGridBagOrganizeGoods:RefreshLifeTime()
    if not XTool.IsNumberValid(self._Id) then
        return
    end
    
    local lifeTime = self._GameControl.TimelimitControl:GetGoodsTotalLifeTimeByUid(self._Id)
    local hasLifeTime = XTool.IsNumberValid(lifeTime)

    self.PanelCountdown.gameObject:SetActiveEx(hasLifeTime)

    if hasLifeTime then
        local leftTime = self._GameControl.TimelimitControl:GetGoodsLeftTimeByUid(self._Id)

        self.ImgCountDownBar.fillAmount = leftTime / lifeTime
    end
end

function XUiGridBagOrganizeGoods:RefreshUsingState()
    if XTool.IsNumberValid(self._Id) then
        self._IsUsed = self._GameControl.GoodsControl:GetIsGoodsUsedById(self._Id)
        self._IsPacking = self._GameControl.GoodsControl:CheckGoodsIsPackingById(self._Id)
        self.GridBtn:SetButtonState((self._IsUsed or self._IsPacking) and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    end
end

function XUiGridBagOrganizeGoods:RefreshValueShow(goodsCfg)
    local cfg = goodsCfg or self._Control:GetGoodsCfgById(self._GoodsId)
    
    local eventBuffMulty = self._GameControl.TimelimitControl:GetEventBuffTotalMulty(cfg)
    local value = cfg.Value

    if XTool.IsNumberValid(eventBuffMulty) then
        value = value + math.ceil(value * eventBuffMulty)
        local baseTxt = XUiHelper.FormatText(self._Control:GetClientConfigText('GoodsValueShowLabel'), value)
        self.TxtPrice.text = XUiHelper.FormatText(self._Control:GetClientConfigText('GoodsValueLabel', 2), baseTxt)
    else
        local baseTxt = XUiHelper.FormatText(self._Control:GetClientConfigText('GoodsValueShowLabel'), value)
        self.TxtPrice.text = XUiHelper.FormatText(self._Control:GetClientConfigText('GoodsValueLabel', 1), baseTxt)
    end
end

function XUiGridBagOrganizeGoods:InitUI()
    self:OnUnSelect()
    self:ResetGridShow()
    ---@type XTableBagOrganizeGoods
    local cfg = self._Control:GetGoodsCfgById(self._GoodsId)
    
    if cfg then
        local hexcolor = string.gsub(cfg.BlockColor, '#', '')
        local blockColor = XUiHelper.Hexcolor2Color(hexcolor)
        
        -- 基本信息
        self.GridBtn:SetRawImage(cfg.IconAddress)
        
        self:RefreshValueShow(cfg)
        
        -- 格子
        self.GridBlock.gameObject:SetActiveEx(false)
        if not XTool.IsTableEmpty(cfg.Blocks) then
            if self._BgBlocks == nil then
                self._BgBlocks = {}
            end
            
            for i, v in ipairs(cfg.Blocks) do
                local img = self._BgBlocks[i]

                if not img then
                    local go = CS.UnityEngine.GameObject.Instantiate(self.GridBlock, self.GridBlock.transform.parent)
                    go.gameObject:SetActiveEx(true)
                    img = go:GetComponent(typeof(CS.UnityEngine.UI.Image))
                    table.insert(self._BgBlocks, img)
                end

                if v == XMVCA.XBagOrganizeActivity.EnumConst.GoodsBlockType.Normal then
                    img.color = blockColor
                end
            end
        end
    end
end

function XUiGridBagOrganizeGoods:GetGoodsId()
    return self._GoodsId
end

function XUiGridBagOrganizeGoods:GetId()
    return self._Id
end

function XUiGridBagOrganizeGoods:OnClickEvent()
    if self._GameControl.GoodsControl:CheckGoodsIsPackingById(self._Id) then
        XUiManager.TipMsg(self._Control:GetClientConfigText('GoodsHadPackingTips'))
        return
    end
    
    if self._GameControl.GoodsControl:GetIsGoodsUsedById(self._Id) then
        return
    end
    
    if self._ClickCb then
        self._ClickCb(self)
    end
end

function XUiGridBagOrganizeGoods:OnSelect()
    self.ImgSelect.gameObject:SetActiveEx(true)
end

function XUiGridBagOrganizeGoods:OnUnSelect()
    self.ImgSelect.gameObject:SetActiveEx(false)
end

function XUiGridBagOrganizeGoods:ResetGridShow()
    if not XTool.IsTableEmpty(self._BgBlocks) then
        for i, v in pairs(self._BgBlocks) do
            v.color = self.GridBlock.color
        end
    end
end

--region 拖拽接口
function XUiGridBagOrganizeGoods:OnBeginDragEvent(eventData)
    if self._GameControl.GoodsControl:GetIsGoodsUsedById(self._Id) then
        return
    end
    
    -- 唤起编辑面板
    self:OnClickEvent()
    -- 定位
    self._GameControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_GOODSINLIST_CALL_OPTIONPOSITION_INIT, eventData)
    self._GameControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_GOODSINLIST_CALL_OPTION_BEGINDRAG, eventData)
end

function XUiGridBagOrganizeGoods:OnDragEvent(eventData)
    if self._GameControl.GoodsControl:GetIsGoodsUsedById(self._Id) then
        return
    end
    
    self._GameControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_GOODSINLIST_CALL_OPTION_DRAGGING, eventData)
end

function XUiGridBagOrganizeGoods:OnEndDragEvent(eventData)
    if self._GameControl.GoodsControl:GetIsGoodsUsedById(self._Id) then
        return
    end
    
    self._GameControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_GOODSINLIST_CALL_OPTION_ENDDRAG, eventData)
end
--endregion

return XUiGridBagOrganizeGoods