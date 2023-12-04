import { LightningElement } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import processData from "@salesforce/apex/ucl_NightlyService.processData";

export default class InvokeService extends LightningElement {  
  handleToggleClick() {
    processData()
      .then((result) => {
        if (result && result.success) {
        const event = new ShowToastEvent({
          title: "Success",
          message: "Data processed successfully",
          variant: "success",
        });
        this.dispatchEvent(event);
      }
      })
      .catch((error) => {
        const event = new ShowToastEvent({
          title: "Error",
          message: error.body.message,
          variant: "error",
        });
        this.dispatchEvent(event);
      });
  }
}
