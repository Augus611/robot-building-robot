*** Settings ***
Documentation       Order several robots from the RobotSpareBin Industries robot builder.

Library    RPA.HTTP
Library    RPA.Browser.Selenium    #auto_close=${FALSE}
Library    RPA.Desktop
Library    RPA.Tables
Library    RPA.Windows
Library    OperatingSystem
Library    RPA.PDF
Library    DateTime
Library    RPA.Archive
Library    RPA.Dialogs
Library    RPA.Robocorp.Vault

*** Tasks ***
Order the robots and save the receipts
    Show starting dialog
    Open the website
    Download the orders file
    Order all robots and save receipts
    Compress receipts into zip file
    [Teardown]    Close the browser

*** Keywords ***

Show starting dialog
    Add heading   Delete old receipts and screenshots?
    Add submit buttons    buttons=No,Yes    default=Yes
    ${result}=    Run dialog
    IF   $result.submit == "Yes"
        Delete old receipts and screenshots
    END
Delete old receipts and screenshots
    Remove Directory    ${OUTPUT_DIR}${/}Receipts    recursive=true
    Remove Directory    ${OUTPUT_DIR}${/}Screenshots    recursive=true
    Remove File    ${OUTPUT_DIR}${/}Receipts*.zip
Open the website
    ${website}=    Get Secret    website
    Open Available Browser    ${website}[url]    maximized=true
Download the orders file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=true

Order all robots and save receipts
    ${orders}=    Read table from CSV    orders.csv
    FOR    ${order}    IN    @{orders}
        Order a robot    ${order}
        #Exit For Loop
    END
Order a robot
    [Arguments]    ${order}
    Click Button    I guess so...
    Select From List By Index    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    //*[@placeholder="Enter the part number for the legs"]    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    Preview
    Click Button    Order
    ${c}=    Get Element Count    //*[@id="order-another"]
    Run Keyword If    ${c} == 0
    ...    Run Keywords    Reload Page    AND    Order a robot    ${order}
    ...  ELSE
    ...    Make and save recepits

Make and save recepits
    ${current_date}=    Get Current Date    result_format=%Y-%m-%d %H-%M-%S
    Wait Until Element Is Visible    id:order-completion
    ${receipt}=    Get Element Attribute    id:order-completion    outerHTML
    Html To Pdf    ${receipt}    ${OUTPUT_DIR}${/}Receipts${/}Receipt ${current_date}.pdf
    RPA.Browser.Selenium.Screenshot    id:robot-preview-image    filename=${OUTPUT_DIR}${/}Screenshots${/}Robot ${current_date}.png
    Add Watermark Image To Pdf    ${OUTPUT_DIR}${/}Screenshots${/}Robot ${current_date}.png    ${OUTPUT_DIR}${/}Receipts${/}Receipt ${current_date}.pdf    ${OUTPUT_DIR}${/}Receipts${/}Receipt ${current_date}.pdf
    Click Button    Order another robot

Compress receipts into zip file
    ${current_date}=    Get Current Date    result_format=%Y-%m-%d %H-%M-%S
    Archive Folder With Zip    ${OUTPUT_DIR}${/}Receipts    ${OUTPUT_DIR}${/}Receipts ${current date}.zip

Close the browser
    Close Browser
    