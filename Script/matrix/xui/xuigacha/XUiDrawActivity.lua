local XUiDrawActivity = XLuaUiManager.Register(XLuaUi, "UiDrawActivity")
local drawActivityControl = require("XUi/XUiGacha/XUiDrawActivityControl")
local LevelMax = 6
local type = { IN = 1, OUT = 2 }
function XUiDrawActivity:OnStart(gachaId)
    self.PreviewList = {}
    self.GachaId = gachaId
    self.GachaCfg = XGachaConfigs.GetGachaCfgById(self.GachaId)
    self.GachaRule = XGachaConfigs.GetGachaRuleCfgById(self.GachaId)
    self.DrawActivityControl = drawActivityControl.New(self, self.GachaCfg, function()
        self:UpdateItemCount()
    end, self)
    self.Is3DSceneLoadFinish = false
    self.ImgMask.gameObject:SetActiveEx(false)

    --self:UpdateInfo()
    self:SetBtnCallBack()
    self:InitPanelPreview()
    self:LoadModelScene()
end

function XUiDrawActivity:SetBtnCallBack()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.BtnMore.CallBack = function()
        self:OnBtnMore()
    end
    self.BtnUseItem.CallBack = function()
        self:OnBtnUseItemClick()
    end
    self.BtnDrawRule.CallBack = function()
        self:OnBtnDrawRuleClick()
    end
end

function XUiDrawActivity:OnEnable()
    if self.Is3DSceneLoadFinish then
        self:UIReset()
    end
    self:UpdateInfo()
end

function XUiDrawActivity:UIReset()
    self.IsReadyForGacha = false
    XUiHelper.SetDelayPopupFirstGet(true)
    self.ImgMask.gameObject:SetActiveEx(true)
    self:PlayAnimation("DrawBegan", function() self.ImgMask.gameObject:SetActiveEx(false) end)
    -- self.PlayableDirector = self.BackGround:GetComponent("PlayableDirector")
    -- self.PlayableDirector:Stop()
    -- self.PlayableDirector:Evaluate()

    --self:PlayLoopAnime()
end

--function XUiDrawActivity:PlayLoopAnime()
--    self.PlayableDirector = XUiHelper.TryGetComponent(self.BackGround.transform, "TimeLine/Loop", "PlayableDirector")
--    if self.PlayableDirector then
--        self.PlayableDirector.gameObject:SetActiveEx(true)
--        self.PlayableDirector:Play()
--        self.PlayGachaAnim = true
--        local behaviour = self.GameObject:AddComponent(typeof(CS.XLuaBehaviour))
--        if self.Update then
--            behaviour.LuaUpdate = function() self:Update() end
--        end
--    end
--end

--function XUiDrawActivity:Update()
--    if self.PlayGachaAnim then
--        if self.PlayableDirector.time >= self.PlayableDirector.duration - 0.1 then
--            if self.IsReadyForGacha then
--                self.DrawActivityControl:ShowGacha()
--            end
--        end
--    end
--end

function XUiDrawActivity:OnDisable()
    XUiHelper.SetDelayPopupFirstGet()
end

function XUiDrawActivity:OnBtnBackClick()
    self:Close()
end

function XUiDrawActivity:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiDrawActivity:OnBtnMore()
    self.PanelPreview.gameObject:SetActiveEx(true)
    self:PlayAnimation("PanelPreviewEnable")
end

function XUiDrawActivity:OnBtnUseItemClick()
    local data = XDataCenter.ItemManager.GetItem(self.GachaCfg.ConsumeId)
    XLuaUiManager.Open("UiTip", data)
end

function XUiDrawActivity:OnBtnDrawRuleClick()
    XLuaUiManager.Open("UiDrawActivityLog",self.GachaId)
end

function XUiDrawActivity:InitPanelPreview()
    self.AllPreviewPanel = {}
    self.PreviewList[type.IN] = {}
    self.PreviewList[type.OUT] = {}
    self.AllPreviewPanel.Transform = self.PanelPreview.transform
    XTool.InitUiObject(self.AllPreviewPanel)
    self.AllPreviewPanel.BtnPreviewConfirm.CallBack = function()
        self.PanelPreview.gameObject:SetActiveEx(false)
    end
    self.AllPreviewPanel.BtnPreviewClose.CallBack = function()
        self.PanelPreview.gameObject:SetActiveEx(false)
    end
    local gachaRewardInfo = XDataCenter.GachaManager.GetGachaRewardInfoById(self.GachaId)
    self.AllPreviewPanel.GridDrawActivity.gameObject:SetActiveEx(false)
    self.GridDrawActivity.gameObject:SetActiveEx(false)
    self:SetPreviewData(gachaRewardInfo, self.AllPreviewPanel.GridDrawActivity, self.AllPreviewPanel.PanelDrawItemSP, self.AllPreviewPanel.PanelDrawItemNA, self.PreviewList[type.IN], type.IN)
    self:SetPreviewData(gachaRewardInfo, self.GridDrawActivity, self.PreviewContent, nil, self.PreviewList[type.OUT], type.OUT, self.GachaRule.PreviewShowCount)

    local countStr = CS.XTextManager.GetText("AlreadyobtainedCount", XDataCenter.GachaManager.GetCurCountOfAll(), XDataCenter.GachaManager.GetMaxCountOfAll())
    self.AllPreviewPanel.PanelTxt.gameObject:SetActiveEx(not XDataCenter.GachaManager.GetIsInfinite())
    self.PanelNumber.gameObject:SetActiveEx(not XDataCenter.GachaManager.GetIsInfinite())
    self.AllPreviewPanel.TxetFuwenben.text = countStr
    self.TxtNumber.text = countStr
    
    self.HintText.text = self.GachaRule.RuleHint or ""
    self.TextName.text = self.GachaRule.GachaName or ""
    self.BtnDrawRule.gameObject:SetActiveEx(self.GachaRule.UiType == XGachaConfigs.UiType.Pay)
end

function XUiDrawActivity:UpdateInfo()
    local icon = XDataCenter.ItemManager.GetItemBigIcon(self.GachaCfg.ConsumeId)
    self.ImgUseItemIcon:SetRawImage(icon)
    self:UpdateItemCount()
end

function XUiDrawActivity:UpdateItemCount()
    self.TxtUseItemCount.text = XDataCenter.ItemManager.GetItem(self.GachaCfg.ConsumeId).Count
end

function XUiDrawActivity:LoadModelScene()
    local sceneUrl = XSceneModelConfigs.GetScenePathById(self.GachaRule.SceneModelId)
    local modelUrl = XSceneModelConfigs.GetModelPathById(self.GachaRule.SceneModelId)
    sceneUrl = (sceneUrl and sceneUrl ~= "") and sceneUrl or self:GetDefaultSceneUrl()
    modelUrl = (modelUrl and modelUrl ~= "") and modelUrl or self:GetDefaultUiModelUrl()
    
    self:LoadUiScene(sceneUrl, modelUrl, function ()
            self:SetGameObject()
            self.Is3DSceneLoadFinish = true
            local groupBaseObj = self.UiSceneInfo.Transform:Find("GroupBase").gameObject
            XTool.DestroyChildren(groupBaseObj)
            --XTool.DestroyChildren()
            local root = self.UiModelGo.transform
            root.position = CS.UnityEngine.Vector3(0,300,0)
            self.BackGround = root
            self:UIReset()
    end, false)
end

function XUiDrawActivity:PushShow(rewardList)
    -- self:OpenChildUi("UiDrawActivityShow")
    -- self:FindChildUiObj("UiDrawActivityShow"):SetData(rewardList, function()
    --     if self.OpenSound then
    --         self.OpenSound:Stop()
    --     end
    --     self:PushResult(rewardList)
    --     self:UpdateInfo()
    -- end, self.BackGround)
    -- if self.CurLoop and not XTool.UObjIsNil(self.CurLoop.gameObject) then
    --     self.CurLoop.gameObject:SetActiveEx(false)
    -- end
    XLuaUiManager.Open("UiDrawNew", nil, rewardList)
    --self.PlayableDirector:Stop()
end

function XUiDrawActivity:PushResult(rewardList)
    XLuaUiManager.Open("UiDrawResult", nil, rewardList, function() end)
end

function XUiDrawActivity:SetPreviewData(gachaRewardInfo, obj, parentSP, parentNA, previewList, previewType, maxCount)
    local count = 1
    for k, v in pairs(gachaRewardInfo) do
        local go = nil
        if previewType == type.IN then
            if v.Rare and parentSP then
                go = CS.UnityEngine.Object.Instantiate(obj, parentSP)
            elseif (not v.Rare) and parentNA then
                go = CS.UnityEngine.Object.Instantiate(obj, parentNA)
            end
        else
            if v.Rare and parentSP then
                if not maxCount or count <= maxCount then
                    go = CS.UnityEngine.Object.Instantiate(obj, parentSP)
                    count = count + 1
                else
                    break
                end
            end
        end

        if go then
            local item = XUiGridCommon.New(self, go)
            local tmpData = {}
            previewList[k] = item
            tmpData.TemplateId = v.TemplateId
            tmpData.Count = v.Count
            local curCount = nil
            if v.RewardType == XGachaConfigs.RewardType.Count then
                curCount = v.CurCount
            end
            item:Refresh(tmpData, nil, nil, nil, curCount)
            item.GameObject:SetActiveEx(true)
        end
    end
end

function XUiDrawActivity:UpDataPreviewData()
    local gachaRewardInfo = XDataCenter.GachaManager.GetGachaRewardInfoById(self.GachaId)
    for i = 1, 2 do
        for k, v in pairs(self.PreviewList[i] or {}) do
            local tmpData = {}
            tmpData.TemplateId = gachaRewardInfo[k].TemplateId
            tmpData.Count = gachaRewardInfo[k].Count
            local curCount = nil
            if gachaRewardInfo[k].RewardType == XGachaConfigs.RewardType.Count then
                curCount = gachaRewardInfo[k].CurCount
            end
            v:Refresh(tmpData, nil, nil, nil, curCount)
        end
    end
    
    local countStr = CS.XTextManager.GetText("AlreadyobtainedCount", XDataCenter.GachaManager.GetCurCountOfAll(), XDataCenter.GachaManager.GetMaxCountOfAll())
    self.AllPreviewPanel.TxetFuwenben.text = countStr
    self.TxtNumber.text = countStr
end