*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.RobotLogListener
Library           RPA.Tables
Library           RPA.FileSystem
Library           RPA.PDF
Library           RPA.Robocorp.Vault
Library           RPA.Archive
Library           RPA.Dialogs
Task Teardown     Clean Up and Reset

*** Variables ***
${ORDERS_URL}                   https://robotsparebinindustries.com/orders.csv
${ORDERS_FILENAME}              orders.csv
${RETRY_TIME}                   5x
${RETRY_INTERVAL}               1s
${PDF_NAME}                     robot_receipt.pdf
${SCREENSHOT_NAME}              screenshot.PNG
${PDF_FILES}                    PDF_Files
${SCREENSHOT_FILES}             Screenshots
${PDF_ZIP}                      PDFs.zip
${PDF_FILE_PATH}                ${OUTPUT_DIR}${/}${PDF_FILES} 
${SCREENSHOT_FILE_PATH}         ${OUTPUT_DIR}${/}${SCREENSHOT_FILES}
${ZIP_DIRECTORY}                ${OUTPUT_DIR}${/}${PDF_ZIP}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${PDF_NAME}    Open Dialog for User Input
    ${vault}    Open the vault
    Open the robot order website    ${vault}
    ${orders}    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}    Store the receipt as a PDF file    ${row}[Order number]    ${PDF_NAME}
        ${screenshot}    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts


*** Keywords ***
Open Dialog for User Input
    Add drop-down
    ...    name=name
    ...    options=robot_receipt,receipt,9545325487
    ...    default=robot_receipt
    ...    label=Choose the name for your PDF receipts
    ${result}=      Run dialog
    ${result.name}    Catenate    SEPARATOR=.    ${result.name}    pdf
    [Return]    ${result.name}
Open the vault
    ${secret}    Get Secret    variabledata
    [Return]    ${secret}
Open the robot order website
    [Arguments]    ${i}
    Open Available Browser    ${i}[robot_url]
Get orders
    Download    ${ORDERS_URL}    overwrite=True
    ${orders}    Read Table From Csv    ${CURDIR}${/}${ORDERS_FILENAME}
    [Return]    ${orders}
Close the annoying modal    
    Click Button    OK
Fill the form
    [Arguments]    ${i}
    Select From List By Value    head    ${i}[Head]
    Select Radio Button    body    ${i}[Body]
    Input Text    xpath://div[@id='root']/div/div/div/div/form/div[3]/input    ${i}[Legs]
    Input Text    address    ${i}[Address]
Preview the robot
    Wait Until Page Contains Element    id:preview
    Wait Until Keyword Succeeds    ${RETRY_TIME}    ${RETRY_INTERVAL}
    ...    Click Element If Visible    id:preview
Submit the order
    Wait Until Page Contains Element    id:order
    Wait Until Page Contains Element    id:robot-preview-image
    Wait Until Keyword Succeeds    ${RETRY_TIME}    ${RETRY_INTERVAL}    Loop Submit Until Success
Loop Submit Until Success
    Mute Run On Failure    Page Should Contain Element
    Click Button    id:order
    Page Should Contain Element    id:receipt
Store the receipt as a PDF file
    [Arguments]    ${i}    ${PDF_NAME}
    Wait Until Page Contains Element    id:receipt
    ${robot_receipt_html}    Get Element Attribute    id:receipt    outerHTML
    ${PDF_NAME}    Catenate    SEPARATOR=    ${i}    ${PDF_NAME}
    Html To Pdf    ${robot_receipt_html}    ${PDF_FILE_PATH}${/}${PDF_NAME}
    [Return]    ${PDF_FILE_PATH}${/}${PDF_NAME}
Take a screenshot of the robot
    [Arguments]    ${i}
    ${SCREENSHOT_NAME}    Catenate    SEPARATOR=    ${i}    ${SCREENSHOT_NAME}
    Screenshot    id:robot-preview-image    ${SCREENSHOT_FILE_PATH}${/}${SCREENSHOT_NAME}
    [Return]    ${SCREENSHOT_FILE_PATH}${/}${SCREENSHOT_NAME}
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${files}    Create List    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}    True
    Close Pdf    ${pdf}
Go to order another robot
    Wait Until Page Contains Element    id:order-another
    Wait Until Keyword Succeeds    ${RETRY_TIME}    ${RETRY_INTERVAL}
    ...    Click Element If Visible    id:order-another
Create a ZIP file of the receipts
        ${zip_file_name}    Set Variable    ${ZIP_DIRECTORY}
        Archive Folder With Zip
        ...    ${PDF_FILE_PATH}
        ...    ${zip_file_name}
Clean Up and Reset
    RPA.FileSystem.Remove File    ${CURDIR}${/}${ORDERS_FILENAME}
    Close Browser