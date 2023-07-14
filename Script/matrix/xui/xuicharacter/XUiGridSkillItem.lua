XUiGridSkillItem = XClass(nil, "XUiGridSkillItem")

function XUiGridSkillItem:Ctor(rootUi, ui, skill, characterId, cb)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.SkillInfo = skill
    self.ClickCallback = cb
    self:InitAutoScript()

    self:UpdateInfo(characterId, self.SkillInfo)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiGridSkillItem:InitAutoScript()
    self:AutoInitUi()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiGridSkillItem:AutoInitUi()
    self.PanelIconTip = XUiHelper.TryGetComponent(self.Transform, "PanelIconTip", nil)
    self.ImgUpgradeTip = XUiHelper.TryGetComponent(self.Transform, "PanelIconTip/ImgUpgradeTip", "Image")
    self.TxtSkillName = XUiHelper.TryGetComponent(self.Transform, "BtnIconBg/ImgBg/TxtSkillName", "Text")
    self.RImgSkillIcon = XUiHelper.TryGetComponent(self.Transform, "RImgSkillIcon", "RawImage")
    self.BtnIconBg = XUiHelper.TryGetComponent(self.Transform, "BtnIconBg", "Button")
end

function XUiGridSkillItem:GetAutoKey(uiNode, eventName)
    if not uiNode then return end
    return eventName .. uiNode:GetHashCode()
end

function XUiGridSkillItem:RegisterListener(uiNode, eventName, func)
    local key = self:GetAutoKey(uiNode, eventName)
    if not key then return end
    local listener = self.AutoCreateListeners[key]
    if listener ~= nil then
        uiNode[eventName]:RemoveListener(listener)
    end

    if func ~= nil then
        if type(func) ~= "function" then
            XLog.Error("XUiGridSkillItem:RegisterListener函数错误, 参数func需要是function类型, func的类型是" .. type(func))
        end

        listener = function(...)
            XSoundManager.PlayBtnMusic(self.SpecialSoundMap[key], eventName)
            func(self, ...)
        end

        uiNode[eventName]:AddListener(listener)
        self.AutoCreateListeners[key] = listener
    end
end

function XUiGridSkillItem:AutoAddListener()
    self.AutoCreateListeners = {}
    XUiHelper.RegisterClickEvent(self, self.BtnIconBg, self.OnBtnIconBgClick)
end
-- auto
function XUiGridSkillItem:OnBtnIconBgClick()
    if self.ClickCallback then
        self.ClickCallback(self.SkillInfo)
    end
end

function XUiGridSkillItem:SetClickCallback(cb)
    self.ClickCallback = cb
end

function XUiGridSkillItem:UpdateInfo(characterId, skill)
    self.SkillInfo = skill

    self.TxtSkillName.text = skill.Name
    self.RImgSkillIcon:SetRawImage(skill.Icon)

    self.ImgUpgradeTip.gameObject:SetActive(false)

    local canUpdate = false
    for _, subSkill in ipairs(skill.subSkills) do
        if (XDataCenter.CharacterManager.CheckCanUpdateSkill(characterId, subSkill.SubSkillId, subSkill.Level)) then
            canUpdate = true
            break
        end
    end

    if (canUpdate) then
        self.ImgUpgradeTip.gameObject:SetActive(true)
    end
end