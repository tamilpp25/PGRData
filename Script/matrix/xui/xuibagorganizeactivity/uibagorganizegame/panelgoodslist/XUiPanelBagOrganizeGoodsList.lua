---@class XUiPanelBagOrganizeGoodsList:XUiNode
---@field _Control XBagOrganizeActivityControl
---@field _GameControl XBagOrganizeActivityGameControl
---@field _GoodsGridPool XPool
local XUiPanelBagOrganizeGoodsList = XClass(XUiNode, 'XUiPanelBagOrganizeGoodsList')
local XUiGridBagOrganizeGoods = require('XUi/XUiBagOrganizeActivity/UiBagOrganizeGame/PanelGoodsList/XUiGridBagOrganizeGoods')

function XUiPanelBagOrganizeGoodsList:OnStart(selectCallBack)
    self._SelectCallBack = selectCallBack
    self._GameControl = self._Control:GetGameControl()
    self._GameControl:AddEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_CANCEL_ADD_GOODS, self.GoodsGridClickCallBack, self)
    self._GameControl:AddEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_REFRESH_GOODS_USING_STATE, self.RefreshAllGoodsUsingState, self)
    self._GameControl:AddEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_REFRESH_GOODS_LIST, self.InitGoods, self)
    self._GameControl:AddEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_RANDOMEVENT_EFFECT_VALID, self.RefreshAllGoodsValue, self)
    
    self._GoodsGridPool = XPool.New(function()
        local go = CS.UnityEngine.GameObject.Instantiate(self.GridGoods, self.GridGoods.transform.parent)
        local grid = XUiGridBagOrganizeGoods.New(go, self, handler(self, self.GoodsGridClickCallBack))
        return grid
    end, function(grid)
        grid:Close()
    end, false)
end

function XUiPanelBagOrganizeGoodsList:InitGoods(isNewGameBegin)
    self._StageId = self._GameControl:GetCurStageId()
    self.GridGoods.gameObject:SetActiveEx(false)
    self:RecycleAllGoodsGrids()

    if isNewGameBegin then
        self:CancelSelectWithoutCallBack()
    end
    
    -- 获取本关卡的所有货物
    local goodsList = self._GameControl.GoodsControl:GetGoodsIdsInList()

    if not XTool.IsTableEmpty(goodsList) then
        -- 货物校验
        if XMain.IsEditorDebug then
            local checkGoodsMap = {}
            for i, v in ipairs(goodsList) do
                if checkGoodsMap[v] then
                    XLog.Error('[货物重复校验]: 存在重复的货物Id: '..tostring(v)..' ,期望Id不重复，请检查关卡'..tostring(self._StageId)..'的配置')
                else
                    checkGoodsMap[v] = true
                end
            end
        end
        -- 生成货物UI
        if self._GoodsGrids == nil then
            self._GoodsGrids = {}
        end
        
        ---@param v XBagOrganizeGoodsEntity
        for i, v in ipairs(goodsList) do
            -- 只显示未正在编辑的部分
            local grid = self._GoodsGridPool:GetItemFromPool()
            grid:Open()
            grid:SetData(v)

            if v == self._SelectGoodsId then
                grid:OnSelect()
                self._SelectedGrid = grid
            end
            
            table.insert(self._GoodsGrids, grid)
        end
    end
end

function XUiPanelBagOrganizeGoodsList:RecycleAllGoodsGrids()
    if not XTool.IsTableEmpty(self._GoodsGrids) then
        for i = #self._GoodsGrids, 1, -1 do
            self._GoodsGridPool:ReturnItemToPool(self._GoodsGrids[i])
            table.remove(self._GoodsGrids, i)
        end
    end
end

function XUiPanelBagOrganizeGoodsList:GoodsGridClickCallBack(grid)
    local isSame = grid == self._SelectedGrid or grid == nil
    
    self:CancelSelectWithoutCallBack()

    if not isSame then
        grid:OnSelect()
        self._SelectedGrid = grid
        self._SelectGoodsId = grid:GetId()
    end

    -- 请求刷新Option
    if self._SelectCallBack then
        self._SelectCallBack(self._SelectedGrid)
    end
end

function XUiPanelBagOrganizeGoodsList:CancelSelectWithoutCallBack()
    if self._SelectedGrid then
        self._SelectedGrid:OnUnSelect()
        self._SelectedGrid = nil
        self._SelectGoodsId = nil
    end
end

function XUiPanelBagOrganizeGoodsList:RefreshAllGoodsUsingState()
    if not XTool.IsTableEmpty(self._GoodsGrids) then
        for i, v in pairs(self._GoodsGrids) do
            v:RefreshUsingState()
        end
    end
end

function XUiPanelBagOrganizeGoodsList:RefreshAllGoodsValue()
    if not XTool.IsTableEmpty(self._GoodsGrids) then
        for i, v in pairs(self._GoodsGrids) do
            v:RefreshValueShow()
        end
    end
end

return XUiPanelBagOrganizeGoodsList