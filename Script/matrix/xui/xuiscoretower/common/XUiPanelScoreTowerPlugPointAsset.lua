---@class XUiPanelScoreTowerPlugPointAsset : XUiNode
---@field private _Control XScoreTowerControl
local XUiPanelScoreTowerPlugPointAsset = XClass(XUiNode, "XUiPanelScoreTowerPlugPointAsset")

function XUiPanelScoreTowerPlugPointAsset:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnTool, self.OnBtnToolClick, nil, true)
    -- 插件点图标
    local icon = self._Control:GetClientConfig("PlugPointIcon")
    if not string.IsNilOrEmpty(icon) then
        self.RImgTool:SetRawImage(icon)
    end
end

---@param chapterId number 章节ID
---@param towerId number 塔ID
---@param floorId number 层ID
function XUiPanelScoreTowerPlugPointAsset:Refresh(chapterId, towerId, floorId)
    self.ChapterId = chapterId
    self.TowerId = towerId
    self.FloorId = floorId
    self:RefreshCount()
end

function XUiPanelScoreTowerPlugPointAsset:RefreshCount()
    if not XTool.IsNumberValid(self.ChapterId) or not XTool.IsNumberValid(self.TowerId) or not XTool.IsNumberValid(self.FloorId) then
        self.TxtTool.text = 0
        return
    end
    -- 总插件点数
    local totalCount = self._Control:GetTowerTotalPlugInPoint(self.ChapterId, self.TowerId)
    -- boss关卡ID
    local bossStageIds = self._Control:GetFloorStageIdsByStageType(self.FloorId, XEnumConst.ScoreTower.StageType.Boss)
    local stageId = bossStageIds[1] or 0
    if not XTool.IsNumberValid(stageId) then
        self.TxtTool.text = totalCount
        return
    end
    -- 已选择的插件ID
    local selectedPluginIds = self._Control:GetStageSelectedPlugIds(self.ChapterId, self.TowerId, stageId)
    -- 已选择插件需要的插件点数
    local needCount = self._Control:GetPlugTotalNeedPoint(selectedPluginIds)
    self.TxtTool.text = math.max(totalCount - needCount, 0)
end

function XUiPanelScoreTowerPlugPointAsset:RefreshCountByPlugIds(plugIds)
    if not XTool.IsNumberValid(self.ChapterId) or not XTool.IsNumberValid(self.TowerId) then
        self.TxtTool.text = 0
        return
    end
    -- 总插件点数
    local totalCount = self._Control:GetTowerTotalPlugInPoint(self.ChapterId, self.TowerId)
    -- 已选择插件需要的插件点数
    plugIds = plugIds or {}
    local needCount = self._Control:GetPlugTotalNeedPoint(plugIds)
    self.TxtTool.text = math.max(totalCount - needCount, 0)
end

function XUiPanelScoreTowerPlugPointAsset:OnBtnToolClick()
    XLuaUiManager.Open("UiScoreTowerPopupAssetDetail")
end

return XUiPanelScoreTowerPlugPointAsset
