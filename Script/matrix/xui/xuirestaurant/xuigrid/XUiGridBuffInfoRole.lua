

local XUiGridBuffInfoRole = XClass(nil, "XUiGridBuffInfoRole")

function XUiGridBuffInfoRole:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

---@param benchId number
---@param areaType number
--------------------------
function XUiGridBuffInfoRole:Refresh(benchId, areaType, buffId)
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    local buff = viewModel:GetBuff(buffId)
   
    
    -- 工作台Id, 工作区域
    local bench = viewModel:GetWorkBenchViewModel(areaType, benchId, true)
    --该工作台未解锁
    if not bench then
        self:RefreshState(false, false, true)
        return
    end
    local isFree = bench:IsFree()
    if isFree then
        self:RefreshState(false, true, false)
        return
    end
    self:RefreshState(true, false, false)
    -- 生产的Id
    local productId = bench:GetProperty("_ProductId")
    -- 生产的员工Id
    local characterId = bench:GetProperty("_CharacterId")

    local staff = viewModel:GetStaffViewModel(characterId)
    self.RImgHead:SetRawImage(staff:GetIcon())
    local addition = buff:GetEffectAddition(areaType, characterId, productId)
    local isEffect = buff:CheckCharacterEffect(characterId) and addition ~= 0
    self.TxtName.text = bench:GetProductName()

    self.TxtNoEffect.gameObject:SetActiveEx(not isEffect)
    self.TxtUpgrade.gameObject:SetActiveEx(isEffect)
    self.ImgUpgrade.gameObject:SetActiveEx(isEffect)
    if isEffect then
        self.TxtNoEffect.gameObject:SetActiveEx(false)
        self.TxtUpgrade.text = XRestaurantConfigs.GetCharacterSkillPercentAddition(addition, areaType, productId)
        self.ImgUpgrade:SetSprite(XRestaurantConfigs.GetUpOrDownArrowIcon(addition > 0 and 1 or 2))
    end
end

function XUiGridBuffInfoRole:RefreshState(isNormal, isFree, isLock)
    self.PanelLock.gameObject:SetActiveEx(isLock)
    self.PanelNormal.gameObject:SetActiveEx(isNormal)
    self.PanelFree.gameObject:SetActiveEx(isFree)
end

return XUiGridBuffInfoRole