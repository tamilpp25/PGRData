local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiPokemonUpgradePreview = XLuaUiManager.Register(XLuaUi, "UiPokemonUpgradePreview")

function XUiPokemonUpgradePreview:OnAwake()
    self:AutoAddListener()
end

function XUiPokemonUpgradePreview:OnStart(monsterId, calllBack)
    self.MonsterId = monsterId
    self.CallBack = calllBack
end

function XUiPokemonUpgradePreview:OnEnable()
    self:UpdatePreview()
end

function XUiPokemonUpgradePreview:UpdatePreview()
    local monsterId = self.MonsterId
    local addLevel, costItemDic = XDataCenter.PokemonManager.GetMonsterCanLevelUpTimes(monsterId)

    local level = XDataCenter.PokemonManager.GetMonsterLevel(monsterId)
    self.TxtLvBefore.text = "Lv." .. level

    local newLevel = level + addLevel
    self.TxtLvNow.text = "Lv." .. newLevel

    local hp = XDataCenter.PokemonManager.GetMonsterHp(monsterId)
    self.TxtBeforeHp.text = hp

    local attack = XDataCenter.PokemonManager.GetMonsterAttack(monsterId)
    self.TxtBeforeAttack.text = attack

    local preHp, preAttack = XDataCenter.PokemonManager.GetMonsterPreHpAndPreAttack(monsterId, newLevel)
    self.TxtNowHp.text = preHp
    self.TxtNowAttack.text = preAttack

    local costItemName, costItemCount = "", ""
    for itemId, itemCount in pairs(costItemDic) do
        costItemName = XItemConfigs.GetItemNameById(itemId)
        costItemCount = itemCount
        break
    end
    local tips = CsXTextManagerGetText("PokemonMonsterAutoLevelUpTips", costItemName, costItemCount)
    self.TxtTip.text = tips
end

function XUiPokemonUpgradePreview:AutoAddListener()
    self.BtnTanchuangClose.CallBack = function() self:OnClickBtnBack() end
    self.BtnConfirm.CallBack = function() self:OnClickBtnConfirm() end
    self.BtnCancel.CallBack = function() self:OnClickBtnBack() end
end

function XUiPokemonUpgradePreview:OnClickBtnBack()
    self:Close()
end

function XUiPokemonUpgradePreview:OnClickBtnConfirm()
    local monsterId = self.MonsterId

    if XDataCenter.PokemonManager.IsMonsterMaxLevel(monsterId) then
        XUiManager.TipText("PokemonMonsterMaxLevel")
        return
    end

    local times = XDataCenter.PokemonManager.GetMonsterCanLevelUpTimes(monsterId)
    if times < 1 then
        XUiManager.TipText("PokemonMonsterAutoLevelUpLackItem")
        return
    end

    local cb = function()
        self:Close()
        self.CallBack()
    end
    XDataCenter.PokemonManager.PokemonLevelUpRequest(monsterId, times, cb)
end