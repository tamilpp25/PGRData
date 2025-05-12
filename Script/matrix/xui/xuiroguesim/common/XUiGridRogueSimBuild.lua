-- 建筑卡片
---@class XUiGridRogueSimBuild : XUiNode
---@field private _Control XRogueSimControl
---@field TxtDetail XUiComponent.XUiRichTextCustomRender
local XUiGridRogueSimBuild = XClass(XUiNode, "XUiGridRogueSimBuild")

function XUiGridRogueSimBuild:OnStart(callback)
    XUiHelper.RegisterClickEvent(self, self.BtnBuild, self.OnBtnBuildClick)
    self.CallBack = callback
    self.PanelProfit.gameObject:SetActiveEx(false)
    self.PanelLock.gameObject:SetActiveEx(false)
    self.PanelNew.gameObject:SetActiveEx(false)
    self.ImgSelect.gameObject:SetActiveEx(false)
    self.PanelNum.gameObject:SetActiveEx(false)
    self.GridScore.gameObject:SetActiveEx(false)
    ---@type UiObject[]
    self.GridScoreList = {}
end

-- 获取建筑蓝图id
function XUiGridRogueSimBuild:GetBluePrintId()
    return self.BluePrintId or 0
end

---@param id number 自增id
function XUiGridRogueSimBuild:Refresh(id)
    self.Id = id
    self.BuildId = self._Control.MapSubControl:GetBuildingConfigIdById(id)
    self:RefreshBuildInfo()
end

---@param buildId number 配置表id
function XUiGridRogueSimBuild:RefreshByBuildId(buildId)
    self.BuildId = buildId
    self:RefreshBuildInfo()
end

---@param bluePrintId number 蓝图id
function XUiGridRogueSimBuild:RefreshByBluePrintId(bluePrintId)
    self.BluePrintId = bluePrintId
    self.BuildId = self._Control.MapSubControl:GetBuildingIdByBluePrintId(bluePrintId)
    self:RefreshBuildInfo()
    self:ShowProfit()
    self:ShowCount(self._Control.MapSubControl:GetBuildingBluePrintCount(bluePrintId))
end

-- 刷新建筑信息
function XUiGridRogueSimBuild:RefreshBuildInfo()
    -- 建筑品质
    self.RImgBg:SetRawImage(self._Control.MapSubControl:GetBuildingQualityIcon(self.BuildId))
    -- 建筑图标
    self.RImgProp:SetSprite(self._Control.MapSubControl:GetBuildingIcon(self.BuildId))
    -- 建筑名称
    self.TxtName.text = self._Control.MapSubControl:GetBuildingName(self.BuildId)
    -- 建筑描述
    self.TxtDetail.requestImage = function(key, img)
        if string.IsNilOrEmpty(key) or XTool.UObjIsNil(img) then
            return
        end
        -- 检测字符串里是否包含Img
        if not string.StartsWith(key, "Img") then
            return
        end
        -- 获取最后一个字符
        local lastChar = string.sub(key, -1)
        local index = tonumber(lastChar)
        local descIcon = self._Control.MapSubControl:GetBuildingDescIcon(self.BuildId, index)
        if descIcon then
            img:SetSprite(descIcon)
        end
    end
    self.TxtDetail.text = self._Control.MapSubControl:GetBuildingDesc(self.BuildId)
    -- 建筑标志
    local tagIcon = self._Control.MapSubControl:GetBuildingTag(self.BuildId)
    local isShowTag = tagIcon and tagIcon ~= ""
    self.ImgTag.gameObject:SetActiveEx(isShowTag)
    if isShowTag then
        self.ImgTag:SetSprite(tagIcon)
    end
    -- 刷新评分列表
    self:RefreshScoreList()
end

-- 刷新评分列表
function XUiGridRogueSimBuild:RefreshScoreList()
    local index = 1
    for _, id in pairs(XEnumConst.RogueSim.CommodityIds) do
        local score = self._Control.MapSubControl:GetBuildingShowScore(self.BuildId, id)
        if score > 0 then
            local grid = self.GridScoreList[index]
            if not grid then
                grid = XUiHelper.Instantiate(self.GridScore, self.ListScore)
                self.GridScoreList[index] = grid
            end
            grid.gameObject:SetActiveEx(true)
            local icon = self._Control.ResourceSubControl:GetCommodityIcon(id)
            grid:GetObject("RImgResource"):SetRawImage(icon)
            grid:GetObject("TxtScore").text = score
            index = index + 1
        end
    end
    for i = index, #self.GridScoreList do
        self.GridScoreList[i].gameObject:SetActiveEx(false)
    end
    self.ListScore.gameObject:SetActiveEx(index > 1)
end

-- 检查金币是否充足
---@param isNotTips boolean 是否不提示
function XUiGridRogueSimBuild:CheckBuildingGoldIsEnough(isNotTips)
    return self._Control.MapSubControl:CheckBuildingBluePrintGoldIsEnough(self.BluePrintId, not isNotTips)
end

-- 显示消耗
function XUiGridRogueSimBuild:ShowProfit()
    if not self.PanelProfit then
        return
    end
    self.PanelProfit.gameObject:SetActiveEx(true)
    -- 检查金币是否充足
    local isEnough = self:CheckBuildingGoldIsEnough(true)
    self.TxtProfitOn.gameObject:SetActiveEx(isEnough)
    self.TxtProfitOff.gameObject:SetActiveEx(not isEnough)
    ---@type UiObject
    local profitUi = isEnough and self.TxtProfitOn or self.TxtProfitOff
    local cost = self._Control.MapSubControl:GetBuildingBluePrintCostGoldCount(self.BluePrintId)
    profitUi:GetObject("TxtProfit").text = cost
    local icon = self._Control.ResourceSubControl:GetResourceIcon(XEnumConst.RogueSim.ResourceId.Gold)
    profitUi:GetObject("RImgCoin"):SetRawImage(icon)
end

-- 显示锁
function XUiGridRogueSimBuild:ShowLock(isLock)
    if self.PanelLock then
        self.PanelLock.gameObject:SetActiveEx(isLock)
    end
end

-- 显示新
function XUiGridRogueSimBuild:ShowNew(isNew)
    if self.PanelNew then
        self.PanelNew.gameObject:SetActiveEx(isNew)
    end
end

-- 显示数量
function XUiGridRogueSimBuild:ShowCount(count)
    if not self.PanelNum then
        return
    end
    self.PanelNum.gameObject:SetActiveEx(true)
    self.TxtNum.text = string.format("x%s", count)
end

-- 设置选中
function XUiGridRogueSimBuild:SetSelect(isSelect)
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(isSelect)
    end
end

-- 点击
function XUiGridRogueSimBuild:OnBtnBuildClick()
    if self.CallBack then
        self.CallBack(self)
    end
end

return XUiGridRogueSimBuild
