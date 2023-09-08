local XUiFubenBossSingleChooseDetailBuff = require("XUi/XUiFubenBossSingle/XUiFubenBossSingleChooseDetailBuff")
local XUiFubenBossSingleChooseDetailTip = require("XUi/XUiFubenBossSingle/XUiFubenBossSingleChooseDetailTip")
local XUiTextScrolling = require("XUi/XUiTaikoMaster/XUiTaikoMasterFlowText")
---@class XUiFubenBossSingleChooseDetail : XLuaUi
---@field BtnTanchuangClose XUiComponent.XUiButton
---@field BtnMask XUiComponent.XUiButton
---@field PanelTab XUiButtonGroup
---@field ImgBoss UnityEngine.UI.RawImage
---@field ImgBuff1 UnityEngine.RectTransform
---@field ImgBuff2 UnityEngine.RectTransform
---@field GridTab1 XUiComponent.XUiButton
---@field GridTab2 XUiComponent.XUiButton
---@field GridTab3 XUiComponent.XUiButton
---@field PanelTip1 UnityEngine.RectTransform
---@field PanelTip2 UnityEngine.RectTransform
---@field TxtNormal1 UnityEngine.UI.Text
---@field TxtPress1 UnityEngine.UI.Text
---@field TxtSelect1 UnityEngine.UI.Text
---@field TxtDisable1 UnityEngine.UI.Text
---@field TxtPressMask1 UnityEngine.RectTransform
---@field TxtSelectMask1 UnityEngine.RectTransform
---@field TxtNormalMask1 UnityEngine.RectTransform
---@field TxtDisableMask1 UnityEngine.RectTransform
---@field TxtNormal2 UnityEngine.UI.Text
---@field TxtPress2 UnityEngine.UI.Text
---@field TxtSelect2 UnityEngine.UI.Text
---@field TxtDisable2 UnityEngine.UI.Text
---@field TxtNormalMask2 UnityEngine.RectTransform
---@field TxtPressMask2 UnityEngine.RectTransform
---@field TxtSelectMask2 UnityEngine.RectTransform
---@field TxtDisableMask2 UnityEngine.RectTransform
---@field TxtNormal3 UnityEngine.UI.Text
---@field TxtPress3 UnityEngine.UI.Text
---@field TxtSelect3 UnityEngine.UI.Text
---@field TxtDisable3 UnityEngine.UI.Text
---@field TxtNormalMask3 UnityEngine.RectTransform
---@field TxtPressMask3 UnityEngine.RectTransform
---@field TxtSelectMask3 UnityEngine.RectTransform
---@field TxtDisableMask3 UnityEngine.RectTransform
local XUiFubenBossSingleChooseDetail = XLuaUiManager.Register(XLuaUi, "UiFubenBossSingleChooseDetail")

function XUiFubenBossSingleChooseDetail:Ctor()
    ---@type XUiFubenBossSingleChooseDetailBuff[]
    self._BuffUiList = nil
    ---@type XUiFubenBossSingleChooseDetailTip[]
    self._TipUiList = nil
    ---@type XUiComponent.XUiButton[]
    self._BtnPanelTabList = nil
    self._BtnTabList = nil
    self._BossList = nil
end

--region 生命周期
function XUiFubenBossSingleChooseDetail:OnAwake()
    self._BuffUiList = {
        XUiFubenBossSingleChooseDetailBuff.New(self.ImgBuff1, self),
        XUiFubenBossSingleChooseDetailBuff.New(self.ImgBuff2, self),
    }
    self._TipUiList = {
        XUiFubenBossSingleChooseDetailTip.New(self.PanelTip1, self),
        XUiFubenBossSingleChooseDetailTip.New(self.PanelTip2, self),
    }
    self._BtnPanelTabList = {
        self.GridTab1,
        self.GridTab2,
        self.GridTab3,
    }
    self._TextScrollingList = {
        {
            XUiTextScrolling.New(self.TxtNormal1, self.TxtNormalMask1),
            XUiTextScrolling.New(self.TxtPress1, self.TxtPressMask1),
            XUiTextScrolling.New(self.TxtSelect1, self.TxtSelectMask1),
            XUiTextScrolling.New(self.TxtDisable1, self.TxtDisableMask1),
        },
        {
            XUiTextScrolling.New(self.TxtNormal2, self.TxtNormalMask2),
            XUiTextScrolling.New(self.TxtPress2, self.TxtPressMask2),
            XUiTextScrolling.New(self.TxtSelect2, self.TxtSelectMask2),
            XUiTextScrolling.New(self.TxtDisable2, self.TxtDisableMask2),
        },
        {
            XUiTextScrolling.New(self.TxtNormal3, self.TxtNormalMask3),
            XUiTextScrolling.New(self.TxtPress3, self.TxtPressMask3),
            XUiTextScrolling.New(self.TxtSelect3, self.TxtSelectMask3),
            XUiTextScrolling.New(self.TxtDisable3, self.TxtDisableMask3),
        },
    }
end

function XUiFubenBossSingleChooseDetail:OnStart(bossList)
    local groupBtnList = {}

    for i = 1, #bossList do
        groupBtnList[i] = self._BtnPanelTabList[i]
    end
    for i = #bossList + 1, #self._BtnPanelTabList do
        self._BtnPanelTabList[i].gameObject:SetActiveEx(false)
    end

    self._BossList = bossList
    self:_Init(groupBtnList)
    self:_RegisterButtonClicks(groupBtnList)
    self.PanelTab:SelectIndex(1)
end

function XUiFubenBossSingleChooseDetail:OnEnable()
    self:_InitTextScrolling()
end

function XUiFubenBossSingleChooseDetail:OnDisable()
    self:_StopAllScrolling()
end

--endregion

--region 按钮事件
function XUiFubenBossSingleChooseDetail:OnBtnTanchuangCloseClick()
    self:Close()
end

function XUiFubenBossSingleChooseDetail:OnBtnMaskClick()
    self:Close()
end

function XUiFubenBossSingleChooseDetail:OnPanelTabClick(index)
    if not self._BossList[index] then
        return
    end

    local bossInfo = XDataCenter.FubenBossSingleManager.GetBossCurDifficultyInfo(self._BossList[index], 1)
    local sectionInfo = XDataCenter.FubenBossSingleManager.GetBossSectionInfo(self._BossList[index])

    if bossInfo then
        self.ImgBoss:SetRawImage(bossInfo.bossIcon)
        self:_RefreshDetail(sectionInfo)
    end
end

--endregion

--region 私有方法
function XUiFubenBossSingleChooseDetail:_RefreshDetail(sectionInfo)
    for i = 1, #self._BuffUiList do
        self._BuffUiList[i]:Close()
    end
    for i = 1, #self._TipUiList do
        self._TipUiList[i]:Close()
    end

    if XTool.IsTableEmpty(sectionInfo) then
        return
    end

    local bossStageCfg = sectionInfo[1]
    local buffDetailIds = bossStageCfg.BuffDetailsId
    local featuresIds = bossStageCfg.FeaturesId

    if not XTool.IsTableEmpty(buffDetailIds) then
        for i = 1, #buffDetailIds do
            local buffUi = self._BuffUiList[i]

            if buffUi then
                buffUi:SetBuffId(buffDetailIds[i], true)
                buffUi:Open()
            end
        end
    elseif not XTool.IsTableEmpty(featuresIds) then
        for i = 1, #featuresIds do
            local tipUi = self._TipUiList[i]

            if tipUi then
                tipUi:SetFeaturesId(featuresIds[i])
                tipUi:Open()
            end
        end
    end
end

---@param bossBtnList XUiComponent.XUiButton[]
function XUiFubenBossSingleChooseDetail:_Init(bossBtnList)
    for i = 1, #self._BossList do
        local bossInfo = XDataCenter.FubenBossSingleManager.GetBossCurDifficultyInfo(self._BossList[i], i)

        bossBtnList[i]:SetNameByGroup(0, bossInfo.bossName)
    end
end

function XUiFubenBossSingleChooseDetail:_RegisterButtonClicks(groupBtnList)
    --在此处注册按钮事件
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnTanchuangCloseClick, true)
    self:RegisterClickEvent(self.BtnMask, self.OnBtnMaskClick, true)
    self.PanelTab:Init(groupBtnList, Handler(self, self.OnPanelTabClick))
end

function XUiFubenBossSingleChooseDetail:_InitTextScrolling()
    local number = #self._BossList

    for i = 1, number do
        for j = 1, #self._TextScrollingList[i] do
            self._TextScrollingList[i][j]:Play()
        end
    end

    for i = number + 1, #self._TextScrollingList do
        for j = 1, #self._TextScrollingList[i] do
            self._TextScrollingList[i][j]:Stop()
        end
    end
end

function XUiFubenBossSingleChooseDetail:_StopAllScrolling()
    for i = 1, #self._TextScrollingList do
        for j = 1, #self._TextScrollingList[i] do
            self._TextScrollingList[i][j]:Stop()
        end
    end
end

--endregion

return XUiFubenBossSingleChooseDetail
