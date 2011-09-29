/**
 * File: invengine.screen.form.SelectInput <br>
 * Copyright: Inventory 2000-2006, GBIC 2005, all rights reserved <br>
 * Changelog:
 * <ul>
 * <li>2006-03-07, 1.0.0, DI Matthijssen
 * <li>2006-05-14; 1.1.0; MA Swertz integration into Inveninge (and major
 * rewrite)
 * <li>2006-05-14; 1.2.0; RA Scheltema major rewrite + cleanup
 * </ul>
 */

package org.molgenis.framework.ui.html;

// jdk
import java.text.ParseException;
import java.util.List;

import org.molgenis.util.Entity;
import org.molgenis.util.Tuple;
import org.molgenis.util.ValueLabel;

/**
 * Input for choosing from an pre-defined series of options. Each option is of
 * class ValueLabel to define values and labels. The options will be shown as
 * dropdown select box.
 */
public class SelectInput extends OptionInput<Object>
{
	private String targetfield;
	private String onchange;

	public SelectInput(Tuple t) throws HtmlInputException
	{
		super(t);
	}

	public SelectInput(String name)
	{
		super(name, null);
	}
	
//  removed! want ambiguous with SelectInput(String name, Object value)	
//	public SelectInput(String name, String label)
//	{
//		this(name);
//		this.setLabel(label);
//	}

	public SelectInput(String name, Object value)
	{
		super(name, value);
	}

	public SelectInput()
	{
		super();
	}

	@Override
	public String toHtml()
	{

		String readonly = (this.isReadonly()) ? " class=\"readonly\" "
				: "";

		String onchange = (this.onchange != null) ? " onchange=\""
				+ this.onchange + "\"" : "";

		if (this.isHidden())
		{
			StringInput input = new StringInput(this.getName(), super
					.getValue());
			input.setLabel(this.getLabel());
			input.setDescription(this.getDescription());
			input.setHidden(true);
			return input.toHtml();
		}

		String optionsHtml = "";

		for (ValueLabel choice : getOptions())
		{
			if (super.getObject() != null && super.getObject().toString().equals(choice.getValue().toString()))
			{
				optionsHtml += "\t<option selected value=\""
						+ choice.getValue() + "\">" + choice.getLabel()
						+ "</option>\n";
			}
			else if (!this.isReadonly())
			{
				optionsHtml += "\t<option value=\"" + choice.getValue()
						+ "\">" + choice.getLabel() + "</option>\n";
			}
		}
		//start with empty option, unless there was already a value selected
		if ((!this.isReadonly() && this.isNillable())
				|| ("".equals(super.getObject()) && this.isNillable()))
		{
			if(super.getObject() != null && super.getObject().toString().equals(""))
				optionsHtml = "\t<option value=\"\">&nbsp;</option>\n" + optionsHtml;
			else
				optionsHtml += "\t<option value=\"\">&nbsp;</option>\n";
		}
		
		
		if (this.uiToolkit == UiToolkit.ORIGINAL)
		{
			return "<select class=\"" + this.getClazz() + "\" id=\""
					+ this.getId() + "\" name=\"" + this.getName() + "\" "
					+ readonly + onchange + ">\n" + optionsHtml.toString()
					+ "</select>\n";
		}
		else if (this.uiToolkit == UiToolkit.DOJO)
		{
			return "<select dojoType=\"dijit.form.Select\" class=\"" + this.getClazz() + "\" id=\""
			+ this.getId() + "\" name=\"" + this.getName() + "\" "
			+ readonly + onchange + " style=\"width: 350px;\">\n" + optionsHtml.toString()
			+ "</select>\n";
		}
		else if(this.uiToolkit == UiToolkit.JQUERY)
		{
			String description = " title=\"" + this.getDescription() + "\"";
			readonly = this.isReadonly() ? "readonly " : "";
			return "<select class=\""+readonly+" ui-widget-content ui-corner-all\" id=\"" 
			+ this.getId() + "\" name=\"" + this.getName() + "\" "
			+ onchange + " style=\"width:16em;\" "+description+">\n" + optionsHtml.toString()
			+ "</select><script>$(\"#"+this.getId()+"\").chosen();</script>\n";
		}
			return "STYLE NOT AVAILABLE";
	}

	public String getTargetfield()
	{
		return targetfield;
	}

	public void setTargetfield(String targetfield)
	{
		this.targetfield = targetfield;
	}

	public String getOnchange()
	{
		return this.onchange;
	}

	public void setOnchange(String onchange)
	{
		this.onchange = onchange;
	}

	public void addOption(Object value, Object label)
	{
		this.getOptions().add(
				new ValueLabel(value.toString(), label.toString()));
	}

	/**
	 * Set the options for the input
	 * 
	 * @param entities
	 *            list of entities to add as options (values)
	 * @param valueField
	 *            field used for identification
	 * @param labelField
	 *            field used for label (what shows on the screen)
	 */
	public void setOptions(List<? extends Entity> entities, String valueField,
			String labelField)
	{
		// clear list
		this.getOptions().clear();

		// add new values and labels
		for (Entity e : entities)
		{
			this.addOption(e.get(valueField), e.get(labelField));
		}
	}
	
	public void setEntityOptions(List<? extends Entity> entities)
	{
		// clear list
		this.getOptions().clear();

		// add new values and labels
		for (Entity e : entities)
		{
			this.addOption(e.getIdValue(), e.getLabelValue());
		}
	}

	@Override
	public String toHtml(Tuple params) throws ParseException,
			HtmlInputException
	{
		return new SelectInput(params).render();
	}
	
	@Override
	public String getCustomHtmlHeaders()
	{
		if(this.uiToolkit == UiToolkit.DOJO)
		{
			return "<script>"+
		    "	dojo.require(\"dijit.form.Select\");"+
		    "</script>";
		} else if (this.uiToolkit == UiToolkit.JQUERY)
		{
//			return "<link rel=\"stylesheet\" href=\"generated-res/lib/jquery-plugins/chosen.css\">\n"+
//					"<script src=\"generated-res/lib/jquery-plugins/chosen.js\" type=\"text/javascript\" language=\"javascript\"></script>\n";
		}
		return "";
	}
}
