//
//  SliderCell.swift
//  
//
//  Created by Rohin Bhushan on 8/11/18.
//

import UIKit

class SliderCell: UITableViewCell {
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var slider: UISlider!
	var titleString = ""
	var delegate : SliderCellDelegate?

	override func awakeFromNib() {
        super.awakeFromNib()
		slider.isContinuous = true
		sliderValueChanged(sender: slider)
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

	// make discrete
	@IBAction func sliderValueChanged(sender: AnyObject) {
		let val = Int(slider.value)
		titleLabel.text = titleString + ": \(val)"
		delegate?.sliderValueChanged(val: slider.value)
	}
}

protocol SliderCellDelegate {
	func sliderValueChanged(val : Float)
}
