local XUiDormMainItem = XClass(nil, "XUiDormMainItem")
local TextManager = CS.XTextManager
local DormMaxCount = 3
local Next = next

function XUiDormMainItem:Ctor(ui, uiRoot)

    self.CurState = false
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    XTool.InitUiObject(self)

    self.ImgDormlMainIcons = {}
    self.ImgDormlMainIcons[1] = self.ImgDormlMainIcon0
    self.ImgDormlMainIcons[2] = self.ImgDormlMainIcon1
    self.ImgDormlMainIcons[3] = self.ImgDormlMainIcon2

    self.ImgHeads = {}
    self.ImgHeads[1] = self.Head0
    self.ImgHeads[2] = self.Head1
    self.ImgHeads[3] = self.Head2

    self.ImgHeadsMask = {}
    self.ImgHeadsMask[1] = self.HeadMask0
    self.ImgHeadsMask[2] = self.HeadMask1
    self.ImgHeadsMask[3] = self.HeadMask2
    self.PetIcons = {}

    self.Gender = XDormConfig.DormCharGender.Max
end

--- 更新数据
---@param itemData XHomeRoomData
---@param state number
--------------------------
function XUiDormMainItem:OnRefresh(itemData, state)
    if not itemData then
        return
    end

    self.CurDormState = state
    self.ItemData = itemData
    self.HudEnable:Play()
    if state == XDormConfig.DormActiveState.Active then
        self.CurDormId = self.ItemData:GetRoomId()
        self.Attdatas = XDataCenter.DormManager.GetDormitoryScoreIcons(self.CurDormId)
        local maxatt = self.Attdatas[1]
        self.UiRoot:SetUiSprite(self.ImgDes, maxatt[1])
        self.TxtNum.text = TextManager.GetText(XDormConfig.DormAttDesIndex[maxatt[3]], maxatt[2] or 0)
        self.DormName = itemData:GetRoomName()
        self.TxtName.text = self.DormName
        
        self:RefreshCharacter()
        self:RefreshPet()
    end

    local gender = self.Gender
    if gender == XDormConfig.DormCharGender.Male then
        self.DormManIcon.gameObject:SetActiveEx(true)
        self.DormWomanIcon.gameObject:SetActiveEx(false)
        self.DormGanIcon.gameObject:SetActiveEx(false)
    elseif gender == XDormConfig.DormCharGender.Female then
        self.DormManIcon.gameObject:SetActiveEx(false)
        self.DormWomanIcon.gameObject:SetActiveEx(true)
        self.DormGanIcon.gameObject:SetActiveEx(false)
    elseif gender == XDormConfig.DormCharGender.Gan then
        self.DormManIcon.gameObject:SetActiveEx(false)
        self.DormWomanIcon.gameObject:SetActiveEx(false)
        self.DormGanIcon.gameObject:SetActiveEx(true)
    else
        self.DormManIcon.gameObject:SetActiveEx(false)
        self.DormWomanIcon.gameObject:SetActiveEx(false)
        self.DormGanIcon.gameObject:SetActiveEx(false)
    end
end

function XUiDormMainItem:SetEvenIconState(state)
    if self.CurState ~= state then
        self.CurState = state
        self.EventIcon.gameObject:SetActive(state)
    end
end

function XUiDormMainItem:RefreshCharacter()
    local characters = self.ItemData:GetCharacter() or {}
    if Next(characters) == nil then
        self.IconsList.gameObject:SetActive(false)
        self.DormManIcon.gameObject:SetActiveEx(false)
        self.DormWomanIcon.gameObject:SetActiveEx(false)
        return
    end
    local gender = XDormConfig.DormCharGender.Max
    self.IconsList.gameObject:SetActive(true)
    for i = 1, DormMaxCount do
        local d = characters[i]
        if d then
            local g = XDormConfig.DormCharSexTypeToGender(XDormConfig.GetCharacterStyleConfigSexById(d.CharacterId))
            if gender ~= g then
                if gender == XDormConfig.DormCharGender.Max then
                    gender = g
                elseif gender ~= XDormConfig.DormCharGender.None then
                    gender = XDormConfig.DormCharGender.None
                end
            end

            local path = XDormConfig.GetCharacterStyleConfigQIconById(d.CharacterId)
            local img = self.ImgDormlMainIcons[i]
            local headgo = self.ImgHeads[i]
            headgo.gameObject:SetActive(true)
            img.gameObject:SetActive(true)
            img:SetRawImage(path, nil, true)
            local isworking = XDataCenter.DormManager.IsWorking(d.CharacterId)
            self.ImgHeadsMask[i].gameObject:SetActive(isworking)
        else
            local headgo = self.ImgHeads[i]
            headgo.gameObject:SetActive(false)
            local img = self.ImgDormlMainIcons[i]
            img.gameObject:SetActive(false)
            self.ImgHeadsMask[i].gameObject:SetActive(false)
        end
    end
    self.Gender = gender
end

function XUiDormMainItem:RefreshPet()
    local petDict = self.ItemData:GetPetDict()
    if XTool.IsTableEmpty(petDict) then
        self.IconsPet.gameObject:SetActiveEx(false)
        return
    end
    self.IconsPet.gameObject:SetActiveEx(true)

    for i = 1, DormMaxCount do
        self["PetHead" .. i].gameObject:SetActiveEx(false)
    end
    local index = 1
    for _, petId in pairs(petDict) do
        local panel = self["PetHead" .. index]
        local template = XDormConfig.GetDormPetTemplate(petId)
        local iconPath = template.HeadRoundIcon
        local icon = self.PetIcons[index]
        if not icon then
            icon = panel:Find("Icon"):GetComponent("RawImage")
            self.PetIcons[index] = icon
        end
        icon:SetRawImage(iconPath)
        panel.gameObject:SetActiveEx(true)
        
        index = index + 1
    end
end

return XUiDormMainItem