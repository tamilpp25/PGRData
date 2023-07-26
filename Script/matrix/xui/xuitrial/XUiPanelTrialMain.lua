local XUiPanelTrialMain = XClass(nil, "XUiPanelTrialMain")
local XUiPanelTrialTaskList = require("XUi/XUiTrial/XUiPanelTrialTaskList")
local XUiPanelTrialType = require("XUi/XUiTrial/XUiPanelTrialType")

function XUiPanelTrialMain:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    XTool.InitUiObject(self)
    self:AddListener()
    self:InitUiAfterAuto()
end

function XUiPanelTrialMain:InitUiAfterAuto()
    self.TrialTaskList = XUiPanelTrialTaskList.New(self.PanelTrialTaskList, self.UiRoot, self)
    self.TrialTypeList = XUiPanelTrialType.New(self.PanelTrialType, self.UiRoot, self)
    self.TxtName.text = CS.XTextManager.GetText("TrialName")
    self.ProForImg = {}
    self.ProForImg[1] = self.ImgPro1.gameObject
    self.ProForImg[2] = self.ImgPro2.gameObject
    self.ProForImg[3] = self.ImgPro3.gameObject
    self.ProForImg[4] = self.ImgPro4.gameObject
    self.ProForImg[5] = self.ImgPro5.gameObject

    self.ProBackEndImg = {}
    self.ProBackEndImg[1] = self.ImgPro1A.gameObject
    self.ProBackEndImg[2] = self.ImgPro2A.gameObject
    self.ProBackEndImg[3] = self.ImgPro3A.gameObject
    self.ProBackEndImg[4] = self.ImgPro4A.gameObject
    self.ProBackEndImg[5] = self.ImgPro5A.gameObject

    self.ProBackEndAnimation = {}
    self.ProForAnimation = {}
    self.ProForAnimation[1] = "AniTrialImgPro1"
    self.ProForAnimation[2] = "AniTrialImgPro2"
    self.ProForAnimation[3] = "AniTrialImgPro3"
    self.ProForAnimation[4] = "AniTrialImgPro4"
    self.ProForAnimation[5] = "AniTrialImgPro5"

    self.ProBackEndAnimation[1] = "AniTrialImgPro6"
    self.ProBackEndAnimation[2] = "AniTrialImgPro7"
    self.ProBackEndAnimation[3] = "AniTrialImgPro8"
    self.ProBackEndAnimation[4] = "AniTrialImgPro9"
    self.ProBackEndAnimation[5] = "AniTrialImgPro10"

    self.ProBackEndFx = {}
    self.ProForFx = {}
    self.ProForFx[1] = self.PanelFx1
    self.ProForFx[2] = self.PanelFx2
    self.ProForFx[3] = self.PanelFx3
    self.ProForFx[4] = self.PanelFx4
    self.ProForFx[5] = self.PanelFx5

    self.ProBackEndFx[1] = self.PanelFx1A
    self.ProBackEndFx[2] = self.PanelFx2A
    self.ProBackEndFx[3] = self.PanelFx3A
    self.ProBackEndFx[4] = self.PanelFx4A
    self.ProBackEndFx[5] = self.PanelFx5A
end

-- 重新设置list的item的状态，让特效出现。
function XUiPanelTrialMain:SetListItemFx()
    self.TrialTaskList:SetListItemFx()
end

-- 关闭list的item的特效，防止特效透ui。
function XUiPanelTrialMain:ClostListItemFx()
    self.TrialTaskList:ClostListItemFx()
end

-- trialtype,1:前段 2:后段
function XUiPanelTrialMain:SeleTrialType(trialtype)
    self.CurTrialType = trialtype
    self.TrialTaskList:UpdateTaskList(trialtype)
end

-- 特效播放完
function XUiPanelTrialMain:FxFisish()
    self.TrialTaskList:OpenFxFinish(true)
    self.TrialTaskList:SetListItemFx()
end

-- 打开
function XUiPanelTrialMain:OpenView()
    XDataCenter.TrialManager.UnLockRed = true
    self.TrialTaskList:OpenFxFinish(false)
    self.UiRoot:PlayAnimation("AnimStartEnable", function()
        self.Dark.gameObject:SetActive(false)
        self:FxFisish()
    end)

    self:RewardGetHandle()
end

-- 关闭
function XUiPanelTrialMain:CloseView()
    for _, v in pairs(self.ProForFx) do
        v.gameObject:SetActive(false)
    end

    for _, v in pairs(self.ProBackEndFx) do
        v.gameObject:SetActive(false)
    end
end

-- 必须保证奖励能正确领取到
function XUiPanelTrialMain:RewardGetHandle()
    local curTrialType = XDataCenter.TrialManager.FinishTrialType()
    if curTrialType == XDataCenter.TrialManager.TrialTypeCfg.TrialFor then
        self.CurTrialType = curTrialType
    else
        if self.UiRoot.RewardUIOpen then--奖励界面还在，不需要判断。
            return
        end
        if XDataCenter.TrialManager.TrialRewardGetedFinish() and not XDataCenter.TrialManager.TypeRewardByTrialtype(XDataCenter.TrialManager.TrialTypeCfg.TrialFor) then
            self.CurTrialType = XDataCenter.TrialManager.TrialTypeCfg.TrialFor
            self.UiRoot:HandleForTrialFinish()
        elseif not XDataCenter.TrialManager.TrialRewardGetedFinish() then
            self.CurTrialType = XDataCenter.TrialManager.TrialTypeCfg.TrialFor
        else
            self.CurTrialType = curTrialType
            if XDataCenter.TrialManager.TrialRewardGetedBackEndFinish() and not XDataCenter.TrialManager.TypeRewardByTrialtype(XDataCenter.TrialManager.TrialTypeCfg.TrialBackEnd) then
                self.UiRoot:HandleBackFinishTips()
            end
        end
    end

    self:SeleTrialType(self.CurTrialType)
    self:SetTrialTypeNameByType(self.CurTrialType)
    self:SetTypeTrialPro()
    self:SetTrialBg(self.CurTrialType)
end

--结算后重新更新数据
function XUiPanelTrialMain:UpdateViewOnFinish()
    self:SeleTrialType(self.CurTrialType)
    self.TrialTypeList:SetTrialTypeNameByType(self.CurTrialType)
    self:SetTypeTrialPro()
end

-- 通过类型设置名字
function XUiPanelTrialMain:SetTrialTypeNameByType(trialtype)
    self.TrialTypeList:SetTrialTypeNameByType(trialtype)
    self.TrialTypeList:InitScrollState(trialtype)
end

-- 设置背景
function XUiPanelTrialMain:SetTrialBg(trialtype)
    self.UiRoot:SetTrialBg(trialtype)
end

-- 设置类型关卡进度
function XUiPanelTrialMain:SetTypeTrialPro()
    if self.CurTrialType == XDataCenter.TrialManager.TrialTypeCfg.TrialFor then
        local cfg = XTrialConfigs.GetForTotalData()
        self.PanelForPro.gameObject:SetActive(true)
        self.PanelBackEndPro.gameObject:SetActive(false)
        self.ImgForPartPro.gameObject:SetActive(true)
        self.ImgBackEndPartPro.gameObject:SetActive(false)

        for k, v in pairs(cfg) do
            if XDataCenter.TrialManager.TrialLevelFinished(v.Id) and XDataCenter.TrialManager.TrialRewardGeted(v.Id) then
                self.ProForImg[k]:SetActive(false)
            else
                self.ProForImg[k]:SetActive(true)
            end
        end
    else
        local cfg = XTrialConfigs.GetBackEndTotalData()
        self.PanelForPro.gameObject:SetActive(false)
        self.PanelBackEndPro.gameObject:SetActive(true)
        self.ImgForPartPro.gameObject:SetActive(false)
        self.ImgBackEndPartPro.gameObject:SetActive(true)

        for k, v in pairs(cfg) do
            if XDataCenter.TrialManager.TrialLevelFinished(v.Id) and XDataCenter.TrialManager.TrialRewardGeted(v.Id) then
                self.ProBackEndImg[k]:SetActive(false)
            else
                self.ProBackEndImg[k]:SetActive(true)
            end
        end
    end
end

-- 前段打完后处理
function XUiPanelTrialMain:SetForTrialFinish(trialtype)
    self:SeleTrialType(trialtype)
    self:SetTrialTypeNameByType(trialtype)
    self:SetTrialBg(trialtype)
end

-- 设置单个进度
function XUiPanelTrialMain:SetTypeTrialSignlePro(index, cb)
    if self.CurTrialType == XDataCenter.TrialManager.TrialTypeCfg.TrialFor then
        self.UiRoot:PlayAnimation(self.ProForAnimation[index], cb)
        self.ProForFx[index].gameObject:SetActive(true)
    else
        self.UiRoot:PlayAnimation(self.ProBackEndAnimation[index], cb)
        self.ProBackEndFx[index].gameObject:SetActive(true)
    end
end

function XUiPanelTrialMain:AddListener()
    self.BtnHelp.CallBack = function() self:OnBtnHelpClick() end
    self.BtnType.CallBack = function() self:OnBtnTypeClick() end
end
-- auto
function XUiPanelTrialMain:OnBtnHelpClick()
    XUiManager.UiFubenDialogTip("", CS.XTextManager.GetText("TrialIllustration") or "")
end

function XUiPanelTrialMain:OnBtnTypeClick()
    if self.CurTrialType == XDataCenter.TrialManager.TrialTypeCfg.TrialFor then

        local cfg = XTrialConfigs.GetTrialTypeCfg(XDataCenter.TrialManager.TrialTypeCfg.TrialFor)
        if not cfg then
            return
        end

        local rewards = XRewardManager.GetRewardList(cfg.RewardId)
        if rewards and rewards[1] then
            XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipPreview(rewards[1].TemplateId)
        end
    else
        local cfg = XTrialConfigs.GetTrialTypeCfg(XDataCenter.TrialManager.TrialTypeCfg.TrialBackEnd)
        if not cfg then
            return
        end
        local rewards = XRewardManager.GetRewardList(cfg.RewardId)
        if rewards and rewards[1] then
            XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipPreview(rewards[1].TemplateId)
        end
    end
end
return XUiPanelTrialMain