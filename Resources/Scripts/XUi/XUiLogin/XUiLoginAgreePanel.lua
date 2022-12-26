local this = {}
local LOCAL_SAVE_AGREE = "LOCAL_SAVE_AGREE"
local LOCAL_SAVE_PRIVE = "LOCAL_SAVE_PRIVE"

function this.OnAwake(rootUi, parent)
    this.GameObject = rootUi.gameObject
    this.Transform = rootUi.transform
    this.Init = false;
    this.Parent = parent;
    XTool.InitUiObject(this)
    this.InitUI()
    this.AutoAddListeners()
end

--第一次登录默认不勾选用户协议
function this.InitUI()
    this.AgreeToggle.isOn = false
    this.UserAgreeLicence = false
end

function this.SaveToLocal()
    local saveAgree = XSaveTool.GetData(LOCAL_SAVE_AGREE)
    local savePrive = XSaveTool.GetData(LOCAL_SAVE_PRIVE)
    if saveAgree == nil or savePrive == nil then
        XSaveTool.SaveData(LOCAL_SAVE_AGREE, XAgreementManager.CurAgree)
        XSaveTool.SaveData(LOCAL_SAVE_PRIVE, XAgreementManager.CurPriva)
        return
    end

    if XAgreementManager.CurAgree == nil or XAgreementManager.CurPriva == nil then
        return
    end

    if XAgreementManager.CurAgree ~= saveAgree or XAgreementManager.CurPriva ~= savePrive then
        XSaveTool.SaveData(LOCAL_SAVE_AGREE, XAgreementManager.CurAgree)
        XSaveTool.SaveData(LOCAL_SAVE_PRIVE, XAgreementManager.CurPriva)
    end
end


function this.AutoAddListeners()
    if this.Init then return end
    this.ConfirmAgree.onClick:AddListener(this.OnCancelAgree)
    this.CancelAgree.onClick:AddListener(this.OnConfirmAgree)
    this.AgreeToggle.onValueChanged:AddListener(this.OnAgreeValueChanged)
    this.Init = true
end

function this.OnConfirmAgree()
    if this.UserAgreeLicence == false then
        --XUiManager.SystemDialogTip("TIPS", "利用規約及びプライバシーポリシーに同意いただけない場合、ゲーム登録できません。", XUiManager.DialogType.OnlySure, nil, nil)
        XUiManager.TipError("Please read and agree to the terms of service and privacy before starting the game")
    else
        --CheckPoint: APPEVENT_GAME_PRIVACY
        XAppEventManager.AppLogEvent(XAppEventManager.CommonEventNameConfig.Game_Privacy)
        this.SaveToLocal()
        if this.Parent and this.Parent.CloseCallBack then
           this.Parent.CloseCallBack()
        end
        this.Hide()
    end
end

function this.OnAgreeValueChanged(isOn)
    this.UserAgreeLicence = isOn
    XAgreementManager.SetUserAgreeLicence(isOn)
end

function this.OnCancelAgree()
    if this.SavedAgree ~= nil then
        XAgreementManager.SetUserAgreeLicence(this.SavedAgree);
    end
    this.Hide()
end

function this.Show()
    local str1, str2 = XAgreementManager.SplitLongText(XAgreementManager.CurAgree)
    this.AgreeTxt1.text = str1
    this.AgreeTxt2.text = str2
    this.PrivTxt2.text = XAgreementManager.CurPriva
    if XAgreementManager.GetUserAgreeLicence() ~= nil then
        this.AgreeToggle.isOn = XAgreementManager.GetUserAgreeLicence()
        this.SavedAgree = XAgreementManager.GetUserAgreeLicence()
    end
end

function this.Hide()
    XLuaUiManager.Close("UiLoginAgreement")
end

return this