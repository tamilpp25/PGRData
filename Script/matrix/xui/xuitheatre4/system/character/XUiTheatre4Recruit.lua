local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiTheatre4RecruitGrid = require("XUi/XUiTheatre4/System/Character/XUiTheatre4RecruitGrid")
local XUiTheatre4ColorResource = require("XUi/XUiTheatre4/System/Resources/XUiTheatre4ColorResource")

---@class XUiTheatre4Recruit : XLuaUi
---@field _Control XTheatre4Control
local XUiTheatre4Recruit = XLuaUiManager.Register(XLuaUi, "UiTheatre4Recruit")

function XUiTheatre4Recruit:OnAwake()
    ---@type XUiPanelRoleModel[]
    self._ModelList = nil
    ---@type XUiTheatre4RecruitGrid[]
    self._CharGrids = nil
    self:RegisterClickEvent(self.BtnBack, self.OnClickClose, nil, true)
    self:RegisterClickEvent(self.BtnMainUi, function()
        XLuaUiManager.RunMain()
    end, nil, true)

    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientConfig("HelpKey"))
    self:RegisterClickEvent(self.BtnRefresh, self.OnClickRefresh)
    self:RegisterClickEvent(self.BtnCharacter, self.OnClickCharacter)
    self.GridMultiPlayerRoomChar.gameObject:SetActiveEx(false)

    self._PanelResource = XUiTheatre4ColorResource.New(self.ListColour, self, function(colorId)
        XLuaUiManager.Open("UiTheatre4Genius", colorId)
    end)
end

function XUiTheatre4Recruit:OnStart()
    self:InitCharGrid()
    self:InitUiScene()
end

function XUiTheatre4Recruit:OnEnable()
    self:Update()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE4_UPDATE_HIRE, self.UpdateAfterNotify, self)
end

function XUiTheatre4Recruit:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE4_UPDATE_HIRE, self.UpdateAfterNotify, self)
end

function XUiTheatre4Recruit:UpdateAfterNotify()
    self:Update()
    self:Set3DCharacter()
end

function XUiTheatre4Recruit:Update()
    self._Control.SetControl:UpdateCharacter()
    local uiData = self._Control.SetControl:GetUiData().Character
    self.TxtNumRefresh.text = uiData.HeadCount
    self.TxtNum.text = uiData.RefreshCount

    --self.BtnColour
    --self.ListColour
    --self.RoomCharCase1
    --self.RoomCharCase2
    --self.RoomCharCase3
    --self.GridMulitiplayerRoomChar
    --self.TxtTitleTips
    --self.TxtNumRefresh

    local characterList = uiData.CharacterList
    for i = 1, #self._CharGrids do
        local grid = self._CharGrids[i]
        local data = characterList[i]
        if data then
            grid:Open()
            grid:Update(data)
        else
            grid:Close()
        end
    end

    self:UpdateCharacterBtn()
end

function XUiTheatre4Recruit:InitUiScene()
    self._Control.SetControl:UpdateCharacter()
    self._Control.SetControl:UpdateMap()
    local uiData = self._Control.SetControl:GetUiData().Character

    local sceneUrl = uiData.SceneUrl
    local modelUrl = uiData.ModelUrl
    self:LoadUiScene(sceneUrl, modelUrl, function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self:Set3DCharacter()
    end)
end

function XUiTheatre4Recruit:Set3DCharacter()
    if not self._ModelList then
        local uiModelRoot = self.UiModelGo.transform
        local models = {
            [1] = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelModelCase1"), self.Name, nil, true, nil, true, true),
            [2] = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelModelCase2"), self.Name, nil, true, nil, true, true),
            [3] = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelModelCase3"), self.Name, nil, true, nil, true, true),
        }
        self._ModelList = models
    end
    local uiData = self._Control.SetControl:GetUiData().Character
    local characterList = uiData.CharacterList
    for i = 1, #self._ModelList do
        ---@type XUiPanelRoleModel
        local model = self._ModelList[i]
        local data = characterList[i]
        if data then
            model:UpdateCharacterModel(data.Model)
            model:ShowRoleModel()
        else
            model:HideRoleModel()
        end
    end
end

function XUiTheatre4Recruit:OnClickRefresh()
    self._Control.SetControl:RequestRefreshCharacters()
end

function XUiTheatre4Recruit:InitCharGrid()
    if not self._CharGrids then
        local ui1 = XUiHelper.Instantiate(self.GridMultiPlayerRoomChar, self.RoomCharCase1)
        local ui2 = XUiHelper.Instantiate(self.GridMultiPlayerRoomChar, self.RoomCharCase2)
        local ui3 = XUiHelper.Instantiate(self.GridMultiPlayerRoomChar, self.RoomCharCase3)

        local list = {
            XUiTheatre4RecruitGrid.New(ui1, self),
            XUiTheatre4RecruitGrid.New(ui2, self),
            XUiTheatre4RecruitGrid.New(ui3, self)
        }
        self._CharGrids = list
    end
end

function XUiTheatre4Recruit:OnClickCharacter()
    self._Control:OpenCharacterPanel()
end

function XUiTheatre4Recruit:UpdateCharacterBtn()
    local isShow = self._Control.SetControl:IsShowCharacterBtn()
    self.BtnCharacter.gameObject:SetActiveEx(isShow)
end

function XUiTheatre4Recruit:OnClickClose()
    XMVCA.XTheatre4:RemoveAdventureUi()
    self:Close()
end

return XUiTheatre4Recruit