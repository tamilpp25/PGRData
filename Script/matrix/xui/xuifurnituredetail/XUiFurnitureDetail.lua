local XUiFurnitureDetail = XLuaUiManager.Register(XLuaUi, "UiFurnitureDetail")
local attrRed = XFurnitureConfigs.AttrType.AttrA
local attrYellow = XFurnitureConfigs.AttrType.AttrB
local attrBule = XFurnitureConfigs.AttrType.AttrC

function XUiFurnitureDetail:OnAwake()
    self:AddListener()
    self:InitLockButtons()
end

function XUiFurnitureDetail:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_DORM_CLOSE_DETAIL, self.OnBtnCloseClick, self)
end

function XUiFurnitureDetail:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_DORM_CLOSE_DETAIL, self.OnBtnCloseClick, self)
end

function XUiFurnitureDetail:OnStart(furnitureId, furnitureConfigId, furnitureRewardId, recycleCallBack, isCloseRecycle, isCloseSuit, isCloseRemake)
    self.FurnitureId = furnitureId
    self.FurnitureConfigId = furnitureConfigId
    self.FurnitureRewardId = furnitureRewardId
    self.RecycleCallBack = recycleCallBack
    self.IsCloseRemake = isCloseRemake

    local isIgnoreRecycle = XFurnitureConfigs.IsIgnoreRecoverySuitByConfigId(furnitureConfigId)
    -- 是否显示回收按钮
    local isHideBtnRecovery = isIgnoreRecycle or (isCloseRecycle ~= nil and isCloseRecycle)

    self.BtnRecovery.gameObject:SetActiveEx(not isHideBtnRecovery)

    if (isCloseSuit == nil or isCloseSuit) then
        self.BtnSuitInfo.gameObject:SetActiveEx(false)
    end

    self:InitConfigInfo()

    if self.FurnitureId then
        self:InitOwnerInfoByObjectId()
        XDataCenter.FurnitureManager.SetDetailData(true, furnitureConfigId)
    else
        self:InitOwnerInfoByConfigId()
        XDataCenter.FurnitureManager.SetDetailData(false, furnitureConfigId)
    end
    
    self:RefreshLabel(furnitureConfigId)
end

function XUiFurnitureDetail:AddListener()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnBg, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnSuitInfo, self.OnBtnSuitInfoClick)
    self:RegisterClickEvent(self.BtnRecovery, self.OnBtnRecoveryClick)
    self:RegisterClickEvent(self.BtnReCreate, self.OnBtnReCreateClick)
end

function XUiFurnitureDetail:InitLockButtons()
    if self.BtnLock then
        self.BtnLock.gameObject:SetActiveEx(false)
        XUiHelper.RegisterClickEvent(self, self.BtnLock, function() self:OnBtnLock() end)
    end
    if self.BtnUnlock then
        self.BtnUnlock.gameObject:SetActiveEx(false)
        XUiHelper.RegisterClickEvent(self, self.BtnUnlock, function() self:OnBtnUnlock() end)
    end
end

function XUiFurnitureDetail:OnBtnCloseClick()
    self:Close()
    XEventManager.DispatchEvent(XEventId.EVENT_DORM_BAG_REFRESH)
end

function XUiFurnitureDetail:OnBtnSuitInfoClick()
    local tp = XFurnitureConfigs.GetFurnitureTemplateById(self.FurnitureConfigId)
    XLuaUiManager.Open("UiDormFieldGuide", tp.SuitId)
    self:Close()
end

-- 确认回收
function XUiFurnitureDetail:OnBtnRecoveryClick()
    if XDataCenter.FurnitureManager.GetFurnitureIsLocked(self.FurnitureId) then
        XUiManager.TipMsg(CS.XTextManager.GetText("DormCannotRecycleLockFurniture"))
        return
    end
    local furnitureRecycleList = { self.FurnitureId }

    -- 屏蔽使用中的家具
    for i = 1, #furnitureRecycleList do
        local isUsing = XDataCenter.FurnitureManager.CheckFurnitureUsing(furnitureRecycleList[i])
        if isUsing then
            XUiManager.TipText("DormFurnitureRecycelUsingTip")
            return
        end
    end
    
    XLuaUiManager.Open("UiFurnitureRecycleObtain", furnitureRecycleList, function()
        XDataCenter.FurnitureManager.DecomposeFurniture(furnitureRecycleList, nil, self.RecycleCallBack)
    end)
end

--重置
function XUiFurnitureDetail:OnBtnReCreateClick()
    if XDataCenter.FurnitureManager.GetFurnitureIsLocked(self.FurnitureId) then
        XUiManager.TipText("DormCannotRecycleLockFurniture")
        return
    end

    local roomId
    if XDataCenter.FurnitureManager.CheckFurnitureUsing(self.FurnitureId) then
        --XUiManager.TipText("DormFurnitureRecycelUsingTip")
        --return
        local furniture = XDataCenter.FurnitureManager.GetFurnitureById(self.FurnitureId)
        if furniture then
            roomId = furniture.DormitoryId
        end
    end

    if not self.RemakeEnough then
        XUiManager.TipText("FurnitureZeroCoin")
        return
    end
    
    local furnitureIds = { self.FurnitureId }
    local furniture = XDataCenter.FurnitureManager.GetFurnitureById(self.FurnitureId)
    local costA, costB, costC = furniture:GetBaseAttr()
    XDataCenter.FurnitureManager.FurnitureRemake(furnitureIds, costA, costB, costC, roomId)
end

function XUiFurnitureDetail:OnBtnLock()
    XDataCenter.FurnitureManager.SetFurnitureLock(self.FurnitureId, false, function() self:SetLocked() end)
end

function XUiFurnitureDetail:OnBtnUnlock()
    XDataCenter.FurnitureManager.SetFurnitureLock(self.FurnitureId, true, function() self:SetLocked() end)
end

function XUiFurnitureDetail:SetLocked()
    if not self.FurnitureId then return end
    local isLocked = XDataCenter.FurnitureManager.GetFurnitureIsLocked(self.FurnitureId)
    if self.BtnLock then self.BtnLock.gameObject:SetActiveEx(isLocked) end
    if self.BtnUnlock then self.BtnUnlock.gameObject:SetActiveEx(not isLocked) end
end

function XUiFurnitureDetail:InitConfigInfo()
    local furnitureConfig = XFurnitureConfigs.GetFurnitureTemplateById(self.FurnitureConfigId)
    local furnitureTypConfig = XFurnitureConfigs.GetFurnitureTypeById(furnitureConfig.TypeId)
    self.TxtName.text = CS.XTextManager.GetText("DormFurnitureName", furnitureConfig.Name, furnitureTypConfig.MinorName, furnitureTypConfig.CategoryName)
    self.TxtScore.text = "???"
    self.TxtFurnitureDesc.text = furnitureConfig.Desc
    local furnitureIcon = furnitureConfig.Icon
    if self.FurnitureId then
        furnitureIcon = XDataCenter.FurnitureManager.GetFurnitureIconById(self.FurnitureId, XDormConfig.DormDataType.Self)
    end
    self.RImgIcon:SetRawImage(furnitureIcon, nil, true)

    -- 套装
    local tp = XFurnitureConfigs.GetFurnitureTemplateById(self.FurnitureConfigId)
    --self.BtnSuitInfo.gameObject:SetActive(tp.SuitId ~= nil and tp.SuitId > 0)

    local suitInfo = nil

    if tp.SuitId > 0 then
        suitInfo = XFurnitureConfigs.GetFurnitureSuitTemplatesById(tp.SuitId)
    end

    if tp.SuitId > 0 and suitInfo then
        self.TxtSuitName.text = suitInfo.SuitName
    else
        self.TxtSuitName.text = CS.XTextManager.GetText("DormFurnitureNotSuit")
    end

    -- 家具属性
    self.TxtRedScore.text = "??"
    self.TxtYellowScore.text = "??"
    self.TxtBlueScore.text = "??"

    -- 特殊效果
    self.TxtEffectDesc.text = "???"
    self.TxtEffectScore.gameObject:SetActive(false)
end

function XUiFurnitureDetail:InitOwnerInfoByObjectId()
    local redTypeName = XFurnitureConfigs.GetDormFurnitureTypeName(attrRed)
    local yoellowTypeName = XFurnitureConfigs.GetDormFurnitureTypeName(attrYellow)
    local blueTypeName = XFurnitureConfigs.GetDormFurnitureTypeName(attrBule)

    local redTypeIcon = XFurnitureConfigs.GetDormFurnitureTypeIcon(attrRed)
    local yoellowTypeIcon = XFurnitureConfigs.GetDormFurnitureTypeIcon(attrYellow)
    local blueTypeIcon = XFurnitureConfigs.GetDormFurnitureTypeIcon(attrBule)

    self:SetUiSprite(self.ImgRed, redTypeIcon)
    self:SetUiSprite(self.ImgYellow, yoellowTypeIcon)
    self:SetUiSprite(self.ImgBlue, blueTypeIcon)

    local redScore = XDataCenter.FurnitureManager.GetFurnitureRedScore(self.FurnitureId)
    local yellowScore = XDataCenter.FurnitureManager.GetFurnitureYellowScore(self.FurnitureId)
    local blueScore = XDataCenter.FurnitureManager.GetFurnitureBlueScore(self.FurnitureId)

    local furnitureType = XDataCenter.FurnitureManager.GetFurnitureConfigByUniqueId(self.FurnitureId).TypeId
    local totalScore = XDataCenter.FurnitureManager.GetFurnitureScore(self.FurnitureId)
    local totalDesc = XFurnitureConfigs.GetFurnitureTotalAttrLevelDescription(furnitureType, totalScore)
    local redScoreDesc = XFurnitureConfigs.GetFurnitureAttrLevelDescription(furnitureType, attrRed, redScore)
    local yellowScoreDesc = XFurnitureConfigs.GetFurnitureAttrLevelDescription(furnitureType, attrYellow, yellowScore)
    local blueScoreDesc = XFurnitureConfigs.GetFurnitureAttrLevelDescription(furnitureType, attrBule, blueScore)

    self.TxtRedScore.text = CS.XTextManager.GetText("DormFurnitureScoreDesc", redTypeName, redScoreDesc)
    self.TxtYellowScore.text = CS.XTextManager.GetText("DormFurnitureScoreDesc", yoellowTypeName, yellowScoreDesc)
    self.TxtBlueScore.text = CS.XTextManager.GetText("DormFurnitureScoreDesc", blueTypeName, blueScoreDesc)
    self.TxtScore.text = CS.XTextManager.GetText("DormFurnitureScoreDesc", CS.XTextManager.GetText("DormTotalScore"), totalDesc)
    local furnitureData = XDataCenter.FurnitureManager.GetFurnitureById(self.FurnitureId)
    self:SetLocked()
    local additionId = furnitureData.Addition
    local additionScoreDesc = ""
    if additionId > 0 then
        self.TxtEffectScore.gameObject:SetActive(true)
        additionScoreDesc = XFurnitureConfigs.GetAdditionalRandomEntry(additionId, true)
    end
    self.TxtEffectDesc.text = XDataCenter.FurnitureManager.GetFurnitureEffectDesc(self.FurnitureId)
    self.TxtEffectScore.text = additionScoreDesc

    local tp = XFurnitureConfigs.GetFurnitureTemplateById(self.FurnitureConfigId)
    self.TxtSuitEffectDesc.gameObject:SetActiveEx(false)

    if tp.SuitId > 0 then
        local suitBgmInfo = XDormConfig.GetDormSuitBgmInfo(tp.SuitId)
        if suitBgmInfo then
            self.TxtSuitEffectDesc.gameObject:SetActiveEx(true)
            self.TxtSuitEffectDesc.text = string.format(CS.XGame.ClientConfig:GetString("DormSuitBgmDesc"), suitBgmInfo.SuitNum, "\n", suitBgmInfo.Name)
            self.TxtSuit.text = CS.XGame.ClientConfig:GetString("DormSuitBgmTitleDesc")
        end
    end
    
    local costA, costB, costC = furnitureData:GetBaseAttr()
    local createCount = costA + costB + costC
    local showReCreate = createCount > 0
    self.BtnReCreate.gameObject:SetActiveEx(showReCreate and not self.IsCloseRemake)
    if showReCreate then
        local coinId = XDataCenter.ItemManager.ItemId.FurnitureCoin
        local recycleCount = self:GetRewardCount()
        local cost = math.max(createCount - recycleCount, 0)
        local own = XDataCenter.ItemManager.GetCount(coinId)
        self.RemakeEnough = own >= cost 
        local key = self.RemakeEnough and "DormBuildEnoughCount" or "DormBuildNoEnoughCount"
        self.BtnReCreate:SetNameByGroup(1, XUiHelper.GetText(key, cost))
        self.BtnReCreate:SetDisable(not self.RemakeEnough, self.RemakeEnough)
        self.BtnReCreate:SetRawImage(XDataCenter.ItemManager.GetItemIcon(coinId))
    end
end

function XUiFurnitureDetail:InitOwnerInfoByConfigId()
    self.BtnReCreate.gameObject:SetActiveEx(false)
    local template = XFurnitureConfigs.GetFurnitureReward(self.FurnitureRewardId)
    if not template then
        return
    end

    local redScore, yellowScore, blueScore = XDataCenter.FurnitureManager.GetRewardFurnitureAttr(template.ExtraAttrId)
    if not redScore or not yellowScore or not blueScore then
        return
    end

    local redTypeName = XFurnitureConfigs.GetDormFurnitureTypeName(attrRed)
    local yoellowTypeName = XFurnitureConfigs.GetDormFurnitureTypeName(attrYellow)
    local blueTypeName = XFurnitureConfigs.GetDormFurnitureTypeName(attrBule)

    local redTypeIcon = XFurnitureConfigs.GetDormFurnitureTypeIcon(attrRed)
    local yoellowTypeIcon = XFurnitureConfigs.GetDormFurnitureTypeIcon(attrYellow)
    local blueTypeIcon = XFurnitureConfigs.GetDormFurnitureTypeIcon(attrBule)

    self:SetUiSprite(self.ImgRed, redTypeIcon)
    self:SetUiSprite(self.ImgYellow, yoellowTypeIcon)
    self:SetUiSprite(self.ImgBlue, blueTypeIcon)

    local furnitureType = XFurnitureConfigs.GetFurnitureTemplateById(self.FurnitureConfigId).TypeId
    local totalScore = XDataCenter.FurnitureManager.GetRewardFurnitureScore(self.FurnitureRewardId)
    local totalDesc = XFurnitureConfigs.GetFurnitureTotalAttrLevelDescription(furnitureType, totalScore)

    local redScoreDesc = XFurnitureConfigs.GetFurnitureAttrLevelDescription(furnitureType, attrRed, redScore)
    local yellowScoreDesc = XFurnitureConfigs.GetFurnitureAttrLevelDescription(furnitureType, attrYellow, yellowScore)
    local blueScoreDesc = XFurnitureConfigs.GetFurnitureAttrLevelDescription(furnitureType, attrBule, blueScore)


    self.TxtRedScore.text = CS.XTextManager.GetText("DormFurnitureScoreDesc", redTypeName, redScoreDesc)
    self.TxtYellowScore.text = CS.XTextManager.GetText("DormFurnitureScoreDesc", yoellowTypeName, yellowScoreDesc)
    self.TxtBlueScore.text = CS.XTextManager.GetText("DormFurnitureScoreDesc", blueTypeName, blueScoreDesc)
    self.TxtBlueScore.text = CS.XTextManager.GetText("DormFurnitureScoreDesc", blueTypeName, blueScoreDesc)
    self.TxtScore.text = CS.XTextManager.GetText("DormFurnitureScoreDesc", CS.XTextManager.GetText("DormTotalScore"), totalDesc)

    local additionId = XDataCenter.FurnitureManager.GetRewardFurnitureEffectId(self.FurnitureRewardId)
    local additionScoreDesc = ""
    if additionId and additionId > 0 then
        self.TxtEffectScore.gameObject:SetActive(true)
        additionScoreDesc = XFurnitureConfigs.GetAdditionalRandomEntry(additionId, true)
    end

    self.TxtEffectDesc.text = XFurnitureConfigs.GetAdditionalRandomIntroduce(additionId)
    self.TxtEffectScore.text = additionScoreDesc
end

function XUiFurnitureDetail:GetRewardCount()
    if not XTool.IsNumberValid(self.FurnitureId) then
        return 0
    end
    local rewards = XDataCenter.FurnitureManager.GetRemakeRewards(self.FurnitureId)
    local coinId = XDataCenter.ItemManager.ItemId.FurnitureCoin
    
    local count = rewards[coinId] and rewards[coinId].Count or 0
    
    return count
end

function XUiFurnitureDetail:RefreshLabel(templateId)
    if self.PanelPet then
        self.PanelPet.gameObject:SetActiveEx(false)
    end
    if self.GoodsLabel then
        self.GoodsLabel:Close()
    end
    if not XTool.IsNumberValid(templateId) then
        return
    end
    if not XUiConfigs.CheckHasLabel(templateId) then
        return
    end
    if not self.GoodsLabel then
        self.GoodsLabel = XUiHelper.CreateGoodsLabel(templateId, self.RImgIcon.transform)
    end
    if self.PanelPet then
        self.TxtFuncDesc.text = XUiConfigs.GetLabelDescription(templateId)
        self.PanelPet.gameObject:SetActiveEx(true)
    end
    self.GoodsLabel:Refresh(templateId, self.PanelPet ~= nil)
end