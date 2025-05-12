local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGachaPanelPreview = XLuaUiManager.Register(XLuaUi,"UiGachaPanelPreview")

function XUiGachaPanelPreview:OnAwake()
    self.PreviewList = {}

    self:AddListener()
    self:InitComponent()
end

function XUiGachaPanelPreview:InitComponent()
    self.GridDrawActivity.gameObject:SetActiveEx(false)
end

function XUiGachaPanelPreview:OnStart(gachaId)
    local gachaRewardInfo = XDataCenter.GachaManager.GetGachaRewardInfoById(gachaId)

    -- 生成奖励格子
    for k, v in pairs(gachaRewardInfo) do
        local go
        local parent

        -- 实例化控件
        if v.Rare and self.PanelDrawItemSP then
            parent = self.PanelDrawItemSP
        elseif (not v.Rare) and self.PanelDrawItemNA then
            parent = self.PanelDrawItemNA
        end
        if parent then
            go = CS.UnityEngine.Object.Instantiate(self.GridDrawActivity, parent)
        end

        -- 实例化脚本
        if go then
            local item = XUiGridCommon.New(self, go)
            self.PreviewList[k] = item

            local tmpData = {}
            tmpData.TemplateId = v.TemplateId
            tmpData.Count = v.Count

            local curCount
            if v.RewardType == XGachaConfigs.RewardType.Count then
                curCount = v.CurCount
            end
            item:Refresh(tmpData, nil, nil, nil, curCount)
            item.GameObject:SetActiveEx(true)
        end
    end

    -- 刷新次数
    local countStr = CS.XTextManager.GetText("GachaAlreadyobtainedCount",
            XDataCenter.GachaManager.GetCurCountOfAll(self.CurGachaId), XDataCenter.GachaManager.GetMaxCountOfAll(self.CurGachaId))
    self.TxetFuwenben.text = countStr
    self.PanelTxt.gameObject:SetActiveEx(not XDataCenter.GachaManager.GetIsInfinite(self.CurGachaId))
end


-----------------------------------------------按钮响应函数------------------------------------------------------

function XUiGachaPanelPreview:AddListener()
    self.BtnPreviewConfirm.CallBack = function()
        self:Close()
    end
    self.BtnPreviewClose.CallBack = function()
        self:Close()
    end
end