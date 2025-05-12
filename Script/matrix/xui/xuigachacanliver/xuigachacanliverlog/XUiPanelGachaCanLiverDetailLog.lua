local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
--========================================== XUiGridGachaCanLiverDetail ==========================================
local XUiGridGachaCanLiverDetail = XClass(XUiNode, 'XUiGridGachaCanLiverDetail')

function XUiGridGachaCanLiverDetail:OnStart(rootUi)
    self.RootUi = rootUi
    self.GridCostItem = XUiHelper.TryGetComponent(self.RewardItem.transform, 'GridCostItem')
    self.RewardProb.gameObject:SetActiveEx(false)
end

function XUiGridGachaCanLiverDetail:RefreshShow(data)
    if self.GridCostItem then
        local gridIcon = XUiGridCommon.New(self.RootUi, self.GridCostItem)
        gridIcon:Refresh({TemplateId = data.TemplateId})
    else
        XLog.Error('缺少道具显示预制GridCostItem的引用')
    end

    -- 只显示前n个
    local count = #data.ProbShow
    for i = 1, count do
        local probability = data.ProbShow[i]

        local probGo = CS.UnityEngine.Object.Instantiate(self.RewardProb, self.RewardProb.transform.parent)
        probGo.gameObject:SetActiveEx(true)
        ---@type UiObject
        local gridProbUiObject = probGo.gameObject:GetComponent("UiObject")

        if gridProbUiObject then
            local txtCount = gridProbUiObject:GetObject('TxtCount')

            if txtCount then
                if not string.IsNilOrEmpty(probability) then
                    txtCount.text = probability
                end
            else
                XLog.Error('UiObject组件缺少文本TxtCount引用')
            end
        else
            XLog.Error('找不到组件UiObject')
        end
    end

    -- 强制刷新一次布局，防止对不齐
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelDropTitleContent)
end

--========================================== XUiPanelGachaCanLiverDetailLog ==========================================
---@class XUiPanelGachaCanLiverDetailLog: XUiNode
---@field _Control XGachaCanLiverControl
---@field RootUi XLuaUi
local XUiPanelGachaCanLiverDetailLog = XClass(XUiNode, "XUiPanelGachaCanLiverDetailLog")

function XUiPanelGachaCanLiverDetailLog:OnStart(rootUi)
    self.RootUi = rootUi
    self.RewardSp.gameObject:SetActiveEx(false)
    self.RewardNor.gameObject:SetActiveEx(false)
end

function XUiPanelGachaCanLiverDetailLog:InitTitleProbailityCount(count)
    for i = 1, 20 do
        local txt = self['TxtTitleProbability'..i]

        if txt then
            txt.gameObject:SetActiveEx(i <= count)
        else
            break
        end
    end

    -- 强制刷新一次布局，防止对不齐
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelDropTitleContent)
end

function XUiPanelGachaCanLiverDetailLog:RefreshUiShow(gachaConfig)
    if self.GachaConfig then
        return
    end
    self.GachaConfig = gachaConfig
    
    local specialRewardProbMinCount = XMath.IntMax()
    
    local list = XDataCenter.GachaManager.GetGachaProbShowById(gachaConfig.Id)
    for i, v in ipairs(list) do
        local tempTrans = v.IsRare and self.RewardSp or self.RewardNor
        local go = CS.UnityEngine.Object.Instantiate(tempTrans, tempTrans.parent)
        local grid = XUiGridGachaCanLiverDetail.New(go, self, self.RootUi)
        grid:Open()
        grid:RefreshShow(v)

        if v.IsRare then
            local probShowCount = #v.ProbShow

            if probShowCount < specialRewardProbMinCount then
                specialRewardProbMinCount = probShowCount
            end
        end
    end

    self:InitTitleProbailityCount(specialRewardProbMinCount)
end

return XUiPanelGachaCanLiverDetailLog