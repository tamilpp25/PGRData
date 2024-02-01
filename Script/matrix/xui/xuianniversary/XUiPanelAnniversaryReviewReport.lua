local XUiPanelAnniversaryReviewReport=XClass(XUiNode,'XUiPanelAnniversaryReviewReport')
local FASHION_QUALITY_LIMIT = 2
local tableInsert = table.insert
local tableSort = table.sort

function XUiPanelAnniversaryReviewReport:OnStart()
    if self.BtnClose then
        self.BtnClose.CallBack=function()
            self:Close()
        end
    end
    if self.Btnshare then
        self.Btnshare.CallBack=function()
            XLuaUiManager.SetMask(true)
            self.Parent:OpenShare(handler(self,self.RefreshShareRewardDisplay))
        end
    end
    self:Refresh()
end

function XUiPanelAnniversaryReviewReport:OnEnable()
    self:RefreshShareRewardDisplay()
    self:DisplayOpenAnimation()
end

function XUiPanelAnniversaryReviewReport:Refresh() 
    self.TxtName.text=XDataCenter.ReviewActivityManager.GetName()
    self.TxtId.text=XDataCenter.ReviewActivityManager.GetPlayerId()
    self.TxtSign.text=XPlayer.Sign
    self.TxtSignUp.text=XDataCenter.ReviewActivityManager.GetCreateTime()
    self.TxtSignUpDay.text=XUiHelper.GetText('AnniverReviewSignUpDay',XDataCenter.ReviewActivityManager.GetExistDayCount())
    self.TxtMedalNum.text=XDataCenter.ReviewActivityManager.GetMedalCount()
    self.TxtCollectionNum.text=XDataCenter.ReviewActivityManager.GetScoreTitleCount()
    self.TxtCharacterNum.text=XDataCenter.ReviewActivityManager.GetCharacterCnt()
    self.TxtCharacterLove.text=XUiHelper.GetText('AnniverReviewReportLoveLabel',XDataCenter.ReviewActivityManager.GetMaxTrustName())
    self.TxtCharacterLoveNum.text=XDataCenter.ReviewActivityManager.GetMaxTrustLvCharacterCnt()
    --涂装收集率
    self.TxtDormNum.text=self:FashionCollectPercent(XDataCenter.FashionManager.GetAllFashionTemplateInTime(), self.Parent.FashionData, XPlayerInfoConfigs.FashionType.Character)
    --self.TxtFurnitureItemNum.text=XDataCenter.ReviewActivityManager.GetFurnitureCount()
    
    --设置头像相关
    local headPortraitInfo = XPlayerManager.GetHeadPortraitInfoById(XPlayer.CurrHeadPortraitId)
    if headPortraitInfo~=nil then
        self.RImgPlayerHead:SetRawImage(headPortraitInfo.ImgSrc)
    end
    local frameInfo=XPlayerManager.GetHeadPortraitInfoById(XPlayer.CurrHeadFrameId)
    if frameInfo~=nil then
        self.RImgIconKuang:SetRawImage(frameInfo.ImgSrc)
    else
        self.RImgIconKuang.gameObject:SetActiveEx(false)
    end
end

function XUiPanelAnniversaryReviewReport:RefreshShareRewardDisplay()
    --分享奖励
    if not self.Panleshare then return end
    if XDataCenter.ReviewActivityManager.IsGetShareReward() then
        self.Panleshare.gameObject:SetActiveEx(false)
    else
        self.Panleshare.gameObject:SetActiveEx(true)
        local rewardId=XDataCenter.ReviewActivityManager.GetShareRewardId()
        if XTool.IsNumberValid(rewardId) then
            local items=XRewardManager.GetRewardList(rewardId)
            if not XTool.IsTableEmpty(items) then
                self.ImageshareReward:SetRawImage(XItemConfigs.GetItemIconById(items[1].TemplateId))
                self.TxtshareReward.text=XUiHelper.GetText('AnniverReviewShareReward',items[1].Count)
            end
        end
    end
end

--==============================--
--desc: 获得涂装数据
--@allFashion: 配置表得到的全部涂装数据
--@ownFashion: 服务器返回的已拥有涂装
--@fashionType: 涂装类型，成员涂装需要过滤泛用式涂装
--@return: 收集率
--==============================--
function XUiPanelAnniversaryReviewReport:FashionCollectPercent(allFashion, ownFashion, fashionType)
    local ownCount = 0
    local allFashionList = {}       --最终数据，拥有涂装排在前面
    
    for k, v in pairs(allFashion) do
        -- 成员涂装需要去除泛用式涂装
        local isWeaponFashion = fashionType ~= XPlayerInfoConfigs.FashionType.Character
        if isWeaponFashion or v.Quality > FASHION_QUALITY_LIMIT then
            local temData = { Data = v, IsLocked = true }
            if ownFashion[k] then
                temData.IsLocked = false
                ownCount = ownCount + 1
            end
            tableInsert(allFashionList, temData)
        end
    end

    -- 计算收集率
    local score = string.format("%.1f", (ownCount / #allFashionList) * 100)

    return score .. "%"
end

function XUiPanelAnniversaryReviewReport:DisplayOpenAnimation()
    if self.PanelReportSpineBg then
        local animation = self.PanelReportSpineBg.SkeletonDataAsset:GetSkeletonData(false):FindAnimation('Enable')
        self.PanelReportSpineBg.AnimationState:SetAnimation(0,animation,false)
        self.Parent:PlayAnimation('PanelReportEnable')
    end
end

return XUiPanelAnniversaryReviewReport