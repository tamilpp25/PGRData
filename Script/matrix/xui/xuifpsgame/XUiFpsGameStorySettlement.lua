---@class XUiFpsGameStorySettlement : XLuaUi 剧情模式挑战胜利结算（关卡内）
---@field _Control XFpsGameControl
local XUiFpsGameStorySettlement = XLuaUiManager.Register(XLuaUi, "UiFpsGameStorySettlement")

function XUiFpsGameStorySettlement:OnAwake()
    self.BtnExit.CallBack = handler(self, self.Close)
end

function XUiFpsGameStorySettlement:OnStart()
    local settleData = XMVCA.XFuben:GetCurFightResult()
    self._Star = self._Control:GetStarsCount(settleData.AddStars)
    self._StageId = settleData.StageId
    self._StageConfig = self._Control:GetStageById(self._StageId)
end

function XUiFpsGameStorySettlement:OnEnable()
    self.Super.OnEnable(self)
    self:SetMouseVisible()

    local uiObject
    local count = math.min(self._Star, #self._StageConfig.StarDesc)
    XUiHelper.RefreshCustomizedList(self.GridStar.parent, self.GridStar, count, function(index, go)
        uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.TxtDesc.text = self._StageConfig.StarDesc[index]
    end)

    if XTool.IsNumberValid(self._StageConfig.UnlockWeapon) then
        self.GridWeapon.gameObject:SetActiveEx(true)
        local weaponConfig = self._Control:GetWeaponById(self._StageConfig.UnlockWeapon)
        ---@type XUiGridFpsGameWeapon
        local weaponGrid = require("XUi/XUiFpsGame/XUiGridFpsGameWeapon").New(self.GridWeapon, self, weaponConfig)
        weaponGrid:SetReceive(self._Control:IsWeaponUnlock(self._StageConfig.UnlockWeapon))
    else
        self.GridWeapon.gameObject:SetActiveEx(false)
    end

    local characterId = self._Control:GetBattleCharacterId()
    if XTool.IsNumberValid(characterId) then
        self.RImgRole.gameObject:SetActiveEx(true)
        self.RImgRole:SetRawImage(XMVCA.XCharacter:GetCharHalfBodyBigImage(characterId))
    else
        self.RImgRole.gameObject:SetActiveEx(false)
    end
end

function XUiFpsGameStorySettlement:OnDestroy()

end

function XUiFpsGameStorySettlement:SetMouseVisible()
    -- 这里只有PC端开启了键鼠以后才能获取到设备
    if CS.XFight.Instance and CS.XFight.Instance.InputSystem then
        local inputKeyboard = CS.XFight.Instance.InputSystem:GetDevice(typeof(CS.XInputKeyboard))
        inputKeyboard.HideMouseEvenByDrag = false
    end
    CS.UnityEngine.Cursor.lockState = CS.UnityEngine.CursorLockMode.None
    CS.UnityEngine.Cursor.visible = true
end

return XUiFpsGameStorySettlement