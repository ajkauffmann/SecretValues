codeunit 70455526 SecretValueAJK
{
    Access = Internal;

    var
        IsolatedStorageKeyTxt: Label '6c33fba1-ae4b-40b9-b805-ee04f6f5be87';
        SecretValueTooLongErr: Label 'Length of secret value may not exceed 215 characters';
        NoSecretValueFoundErr: Label 'Could not find the secret value.';
        ExecutionContextErr: Label 'This function can ony be called during installation or upgrade.';

    [NonDebuggable]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::SecretValueMgtAJK, 'OnSetSecretValue', '', false, false)]
    local procedure SetSecretValue(SecretValue: Text[215])
    begin
        StoreSecretValueInIsolatedStorage(SecretValue);
    end;

    [NonDebuggable]
    procedure ImportSecretValue()
    begin
        if not (GetCurrentModuleExecutionContext() in [ExecutionContext::Install, ExecutionContext::Upgrade]) then
            Error(ExecutionContextErr);
        NavApp.LoadPackageData(Database::SecretValueAJK);
        MoveSecretValueToIsolatedStorage();
    end;

    [NonDebuggable]
    local procedure MoveSecretValueToIsolatedStorage()
    var
        SecretValue: Record SecretValueAJK;
        SecretValueText: Text;
    begin
        if not SecretValue.FindFirst() then
            exit;

        SecretValueText := SecretValue.GetSecretTextValue(2);
        if SecretValueText = '' then
            exit;
        StoreSecretValueInIsolatedStorage(SecretValueText);

        SecretValue.DeleteAll();
    end;

    [NonDebuggable]
    local procedure StoreSecretValueInIsolatedStorage(SecretValue: Text)
    begin
        if StrLen(SecretValue) > 215 then
            Error(SecretValueTooLongErr);
        if IsolatedStorage.Contains(IsolatedStorageKeyTxt, DataScope::Module) then
            IsolatedStorage.Delete(IsolatedStorageKeyTxt, DataScope::Module);

        if not EncryptionEnabled() then
            IsolatedStorage.Set(IsolatedStorageKeyTxt, SecretValue, DataScope::Module)
        else
            IsolatedStorage.SetEncrypted(IsolatedStorageKeyTxt, SecretValue, DataScope::Module);
    end;

    [NonDebuggable]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::SecretValueMgtAJK, 'OnPrepareSecretValueTableForExport', '', false, false)]
    local procedure PrepareSecretValueTableForExport()
    var
        SecretValue: Record SecretValueAJK;
        RandomTextMgt: Codeunit RandomTextMgtAJK;
    begin
        SecretValue.DeleteAll();
        SecretValue.SetSecretTextValue(1, RandomTextMgt.GenerateRandomText(50));
        SecretValue.SetSecretTextValue(2, GetSecretValue());
        SecretValue.SetSecretTextValue(3, RandomTextMgt.GenerateRandomText(50));
        SecretValue.Insert();
    end;

    [NonDebuggable]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::SecretValueMgtAJK, 'OnRemoveSecretValueTableData', '', false, false)]
    local procedure RemoveSecretValueTableData()
    var
        SecretValue: Record SecretValueAJK;
    begin
        SecretValue.DeleteAll();
    end;

    [NonDebuggable]
    procedure GetSecretValue() SecretValue: Text
    begin
        if not IsolatedStorage.Get(IsolatedStorageKeyTxt, DataScope::Module, SecretValue) then
            Error(NoSecretValueFoundErr);
    end;
}