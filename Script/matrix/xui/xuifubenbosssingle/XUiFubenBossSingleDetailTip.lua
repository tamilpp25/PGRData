---@class XUiFubenBossSingleDetailTip : XUiNode
---@field PanelFeatures UnityEngine.RectTransform
---@field PanelBuffDetail UnityEngine.RectTransform
---@field TxtFeatureTitle UnityEngine.UI.Text
---@field TxtFeatureDesc UnityEngine.UI.Text
---@field GridBuffDetail UnityEngine.RectTransform
---@field PanelBuffContent UnityEngine.RectTransform
---@field BtnDetail XUiComponent.XUiButton
---@field PanelHideBg UnityEngine.RectTransform
---@field PanelBg UnityEngine.RectTransform
local XUiFubenBossSingleDetailTip = XClass(XUiNode, "XUiFubenBossSingleDetailTip")
local XUiFubenBossSingleChooseDetailBuff = require("XUi/XUiFubenBossSingle/XUiFubenBossSingleChooseDetailBuff")

--region 生命周期
function XUiFubenBossSingleDetailTip:OnStart(bossStageConfig)
    self._BossStageConfig = bossStageConfig or self._BossStageConfig
    ---@type XUiFubenBossSingleChooseDetailBuff[]
    self._GridBuffList = self._GridBuffList or {}
    self.GridBuffDetail.gameObject:SetActiveEx(false)
    self:_RegisterButtonClicks()
end

function XUiFubenBossSingleDetailTip:OnEnable()
    self:_Refresh()
end

--endregion

--region 按钮事件
function XUiFubenBossSingleDetailTip:OnBtnDetailClick()
    XLuaUiManager.Open("UiFubenBossSingleHide", self._BossStageConfig)
end

--endregion

function XUiFubenBossSingleDetailTip:SetBossStageConfig(bossStageConfig)
    self._BossStageConfig = bossStageConfig
end

function XUiFubenBossSingleDetailTip:_Refresh()
    local bossStageCfg = self._BossStageConfig
    local buffDetailIds = bossStageCfg.BuffDetailsId
    local featuresIds = bossStageCfg.FeaturesId
    local showFeatures = featuresIds and #featuresIds > 0
    local showBuff = buffDetailIds and #buffDetailIds > 0

    if not showBuff and not showFeatures then
        self:Close()
        return
    end

    local isHideBoss = bossStageCfg.DifficultyType == XFubenBossSingleConfigs.DifficultyType.Hide

    self.PanelFeatures.gameObject:SetActiveEx(showFeatures)
    self.PanelBuffDetail.gameObject:SetActiveEx(showBuff)
    self.PanelHideBg.gameObject:SetActiveEx(isHideBoss)
    self.PanelBg.gameObject:SetActiveEx(not isHideBoss)

    -- 设置词缀
    if showFeatures then
        local featureCfg = XFubenConfigs.GetFeaturesById(featuresIds[1])

        self.TxtFeatureTitle.text = featureCfg.Name
        self.TxtFeatureDesc.text = featureCfg.Desc
    end

    for i = 1, #self._GridBuffList do
        self._GridBuffList[i]:Close()
    end

    if showBuff then
        for i = 1, #buffDetailIds do
            local grid = self._GridBuffList[i]

            if not grid then
                local ui = XUiHelper.Instantiate(self.GridBuffDetail, self.PanelBuffContent)

                grid = XUiFubenBossSingleChooseDetailBuff.New(ui, self, self.Parent)
                self._GridBuffList[i] = grid
            end

            grid:SetBuffId(buffDetailIds[i], false)
            grid:Open()
        end
    end
end

--region 私有方法
function XUiFubenBossSingleDetailTip:_RegisterButtonClicks()
    --在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnDetail, self.OnBtnDetailClick, true)
end

--endregion

return XUiFubenBossSingleDetailTip
