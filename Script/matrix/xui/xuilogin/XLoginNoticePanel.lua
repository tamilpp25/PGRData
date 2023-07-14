local this = {}

function this.OnAwake(rootUi)
    this.GameObject = rootUi.gameObject
    this.Transform = rootUi.transform
    this.LinkConfigs = XTableManager.ReadByIntKey("Client/Activity/ActivityLink.tab", XTable.XTableActivityLink, "Id")
    XTool.InitUiObject(this)
    this.AutoAddListeners()
end

function this.AutoAddListeners()
    this.BtnTanchuangClose.onClick:AddListener(this.CloseMenu)
    this.BtnNotice.onClick:AddListener(this.OpenNotice)
    for i = 1, 3 do
        this["BtnLink" .. i].onClick:AddListener(function()
            this.OpenLink(i)
        end)
        this["MenuInfoText" .. i].text = this.LinkConfigs[i].LinkName
    end
end

function this.OpenLink(index)
    if this.LinkConfigs[index] == nil then return end
    local url = this.LinkConfigs[index].LinkUrl
    CS.UnityEngine.Application.OpenURL(url)
end

function this.OpenNotice()
    local hasNotice = XDataCenter.NoticeManager.OpenLoginNotice()
    if not hasNotice then
        XUiManager.TipError("No notice")
    end
end

function this.CloseMenu()
    this.GameObject:SetActiveEx(false)
    XLuaUiManager.Close("UiLoginDialog")
end

return this