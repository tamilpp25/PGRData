---@class XGridCharacterV2P6:XUiNode
---@field _Control XCharacterControl
local XGridCharacterV2P6 = XClass(XUiNode, "XGridCharacterV2P6")

function XGridCharacterV2P6:OnStart(rootFilter)
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag
    self.RootFilter = rootFilter
end

-- 过时的接口，不要再使用！！！supportData的逻辑请在自己创建的Grid里实现
function XGridCharacterV2P6:UpdateSupportAbandoned(supportData) 
    if XTool.IsTableEmpty(supportData) then return end

    self:SetInTeam(false)

    local characterId = self.Character.Id

    if self.PanelSupportLock then
        local lockSupport = supportData.CheckLockSupportCb and supportData.CheckLockSupportCb(characterId)
        self.PanelSupportLock.gameObject:SetActiveEx(lockSupport)
    end

    if self.PanelSupportIn then
        local showSupport = supportData.CheckInSupportCb(characterId)
        self.PanelSupportIn.gameObject:SetActiveEx(showSupport)
    end

    if self.PanelHighPriority and supportData.CheckHighPriority then
        local showHighPriority = false
        local icon = false
        if supportData.CheckHighPriority then
            showHighPriority, icon = supportData.CheckHighPriority(characterId)
        end
        self.PanelHighPriority.gameObject:SetActiveEx(showHighPriority)
        if icon then
            local tran = self.PanelHighPriority.transform:Find("UpTag/RImgGuildWarUP")
            local rawImage = tran:GetComponent("RawImage")
            rawImage:SetRawImage(icon)
        end
    end
end

function XGridCharacterV2P6:UpdateFragmentInfo()
    local bornQuality = XMVCA.XCharacter:GetCharMinQuality(self.Character.Id)
    local characterType = XMVCA.XCharacter:GetCharacterType(self.Character.Id)
    local needFragment = XCharacterConfigs.GetComposeCount(characterType, bornQuality)
    self.TxtCurCount.text = self.CharacterAgency:GetCharUnlockFragment(self.Character.Id)
    self.TxtNeedCount.text = needFragment
end

function XGridCharacterV2P6:UpdateBaseCharacterInfo()
    self.TxtLevel.text = self.Character.Level
    self.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(self.CharacterAgency:GetCharacterQuality(self.Character.Id)))

    -- self:UpdateGrade()
    -- self:UpdateFight()
end

function XGridCharacterV2P6:CheckShowBaseInfo()
    local isFragment = self.CharacterAgency:CheckIsFragment(self.Character.Id)
    self.PanelLevel.gameObject:SetActiveEx(not isFragment)
    self.RImgQuality.gameObject:SetActiveEx(not isFragment)
    self.ImgLock.gameObject:SetActiveEx(isFragment)
    self.PanelFragment.gameObject:SetActiveEx(isFragment)
    self.RImgHeadIcon:SetRawImage(self.CharacterAgency:GetCharSmallHeadIcon(self.Character.Id))
    
    -- 初始品质
    self.PanelInitQuality.gameObject:SetActiveEx(true)
    local initQuality = self.CharacterAgency:GetCharacterInitialQuality(self.Character.Id)
    local icon = self.CharacterAgency:GetModelCharacterQualityIcon(initQuality).IconCharacterInit
    self.ImgInitQuality:SetSprite(icon)    

    self:UpdateUniframe()
end

function XGridCharacterV2P6:SetData(character)
    if not character then
        return
    end

    ---@type XCharacter
    self.Character = character
    self:CheckShowBaseInfo()
    local isFragment = self.CharacterAgency:CheckIsFragment(self.Character.Id)
    self.IsFragment = isFragment
    if isFragment then
        self:UpdateFragmentInfo()
    else
        if not XRobotManager.CheckIsRobotId(character.id) then
            self.Character = self.CharacterAgency:GetCharacter(self.Character.Id) -- 一定要拿到最新的数据
        end
        self:UpdateBaseCharacterInfo()
    end
end

-- public choose start
function XGridCharacterV2P6:UpdateIconEquipGuide()
    -- 装备目标
    if self.IconEquipGuide then
        self.IconEquipGuide.gameObject:SetActiveEx(XDataCenter.EquipGuideManager.IsEquipGuideCharacter(self.Character.Id))
    end
end

function XGridCharacterV2P6:UpdateRedPoint()
    XRedPointManager.CheckOnce(self.OnCheckCharacterRedPoint, self, 
    { XRedPointConditions.Types.CONDITION_CHARACTER }, 
    self.Character.Id)
end

function XGridCharacterV2P6:UpdateGrade()
    local grade = self.Character.Grade or self.CharacterAgency:GetCharacterGrade(self.Character.Id) or 1
    self.RImgGrade:SetRawImage(XCharacterConfigs.GetCharGradeIcon(self.Character.Id, grade))
end

function XGridCharacterV2P6:UpdateNew()
    local v = XTool.IsNumberValid(self.Character.NewFlag) and not self.Character.CollectState
    self.TxtNew.gameObject:SetActiveEx(v)
end

function XGridCharacterV2P6:UpdateCollect()
    local v = self.Character.CollectState
    self.PanelCollect.gameObject:SetActiveEx(v)
end

function XGridCharacterV2P6:PlayPanelCollectEffect()
    XUiHelper.PlayAllChildParticleSystem(self.PanelCollect)
end

function XGridCharacterV2P6:UpdateUniframe()
    local isUniframe = self.CharacterAgency:GetIsIsomer(self.Character.Id)
    self.PanelUniframe.gameObject:SetActiveEx(isUniframe)
end

function XGridCharacterV2P6:UpdateEnergy()
    -- 元素图标
    local characterViewModel = self.Character:GetCharacterViewModel()
    local obtainElementIcons = characterViewModel:GetObtainElementIcons()
    local elementIcon
    for i = 1, 3 do
        elementIcon = obtainElementIcons[i]
        if self["RImgCharElement" .. i] then
            self["RImgCharElement" .. i].gameObject:SetActiveEx(elementIcon ~= nil)
            if elementIcon then
                self["RImgCharElement" .. i]:SetRawImage(elementIcon)
            end
        end
    end
    self.PanelEnergy.gameObject:SetActiveEx(true)
end

function XGridCharacterV2P6:UpdateFight()
    if self.IsFragment then
        self.PanelFight.gameObject:SetActiveEx(false)
        return
    end
    
    self.TxtFight.text = self.CharacterAgency:GetCharacterHaveRobotAbilityById(self.Character.Id)
    self.PanelFight.gameObject:SetActiveEx(true)
end
-- public choose end

function XGridCharacterV2P6:SetSelect(isSelect)
    if isSelect == self.IsSelect then
        return
    end

    self.IsSelect = isSelect
    self.ImgSelected.gameObject:SetActiveEx(isSelect)
end

function XGridCharacterV2P6:HideRedPoint()
    if self.ImgRedPoint then
        self.ImgRedPoint.gameObject:SetActiveEx(false)
    end
end

function XGridCharacterV2P6:OnCheckCharacterRedPoint(count)
    if self.ImgRedPoint then
        self.ImgRedPoint.gameObject:SetActiveEx(count >= 0)
    end
end

function XGridCharacterV2P6:SetInTeam(isInTeam)
    if self.ImgInTeam then
        self.ImgInTeam.gameObject:SetActiveEx(isInTeam)
    end
end

function XGridCharacterV2P6:SetCurSignState(state)
end

function XGridCharacterV2P6:DoFold()
    -- self:PlayAnimation("AnimFold")
end

function XGridCharacterV2P6:DoUnfold()
    -- self:PlayAnimation("AnimUnFold")
end

function XGridCharacterV2P6:PlayAnimation(animeName)
    -- local animTrans = self.Transform:Find("Animation"):FindTransform(animeName)
    -- if not animTrans.gameObject.activeInHierarchy then
    --     return
    -- end
    -- animTrans:GetComponent("PlayableDirector"):Play()
end

return XGridCharacterV2P6