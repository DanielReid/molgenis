<#--helper functions-->
<#include "GeneratorHelper.ftl">

<#--#####################################################################-->
<#--                                                                   ##-->
<#--         START OF THE OUTPUT                                       ##-->
<#--                                                                   ##-->
<#--#####################################################################-->
/* File:        ${model.getName()}/model/${entity.getName()}.java
 * Copyright:   GBIC 2000-${year?c}, all rights reserved
 * Date:        ${date}
 * 
 * generator:   ${generator} ${version}
 *
 * 
 * THIS FILE HAS BEEN GENERATED, PLEASE DO NOT EDIT!
 */

package ${package};

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
<#list allFields(entity) as f>
<#if f.type="xref" ||  f.type="mref" >
import java.util.Map;
import java.util.TreeMap;
<#break>
</#if>
</#list>
import org.apache.log4j.Logger;
import org.molgenis.framework.db.CsvToDatabase;
import org.molgenis.framework.db.Database;
import org.molgenis.framework.db.DatabaseException;
import org.molgenis.framework.db.Query;
import org.molgenis.framework.db.Database.DatabaseAction;
import org.molgenis.util.CsvReader;
import org.molgenis.util.Tuple;

${imports(model, entity, "")}

/**
 * Reads ${JavaName(entity)} from a delimited (csv) file, resolving xrefs to ids where needed, that is the tricky bit ;-)
 */
public class ${JavaName(entity)}CsvReader extends CsvToDatabase<${JavaName(entity)}>
{
	public static final transient Logger logger = Logger.getLogger(${JavaName(entity)}CsvReader.class);
	
	<#assign has_xrefs=false />
	<#list allFields(entity) as f><#if (f.type == 'xref' || f.type == 'mref') && f.getXrefLabelNames()[0] != f.xrefFieldName><#assign has_xrefs=true>
	<#if f.xrefLabels?size &gt; 1>
	//foreign key map for composite xref '${name(f)}' (maps ${name(f.xrefEntity)}.${csv(f.xrefLabelNames)} -> ${name(f.xrefEntity)}.${name(f.xrefField)})			
	final Map<String,${JavaType(f.xrefField)}> ${name(f)}Keymap = new TreeMap<String,${JavaType(f.xrefField)}>();	
	<#else>
	//foreign key map for xref '${name(f)}' (maps ${name(f.xrefEntity)}.${csv(f.xrefLabelNames)} -> ${name(f.xrefEntity)}.${name(f.xrefField)})			
	final Map<${type(f.xrefLabels[0])},${JavaType(f.xrefField)}> ${name(f)}Keymap = new TreeMap<${type(f.xrefLabels[0])},${JavaType(f.xrefField)}>();	
	</#if>
	</#if></#list>	
			
	/**
	 * Imports ${JavaName(entity)} from tab/comma delimited File
	 * @param db database to import into
	 * @param reader csv reader to load data from
	 * @param defaults to set default values for each row
	 * @param dbAction indicating wether to add,update,remove etc
	 * @param missingValues indicating what value in the csv is treated as 'null' (e.g. "" or "NA")
	 * @return number of elements imported
	 */
	public int importCsv(final Database db, CsvReader reader, final Tuple defaults, final DatabaseAction dbAction, final String missingValues) throws DatabaseException, IOException, Exception 
	{
		//cache for entities of which xrefs couldn't be resolved (e.g. if there is a self-refence)
		//these entities can be updated with their xrefs in a second round when all entities are in the database
		final List<${JavaName(entity)}> ${name(entity)}sMissingRefs = new ArrayList<${JavaName(entity)}>();
	
		//cache for objects to be imported from file (in batch)
		final List<${JavaName(entity)}> ${name(entity)}List = new ArrayList<${JavaName(entity)}>(BATCH_SIZE);
		//wrapper to count
		final IntegerWrapper total = new IntegerWrapper(0);
		reader.setMissingValues(missingValues);
		for(Tuple tuple: reader)
		{
			//parse object, setting defaults and values from file
			${JavaName(entity)} object = new ${JavaName(entity)}();
			object.set(defaults, false); 
			object.set(tuple, false);				
			${name(entity)}List.add(object);		
			
			//add to db when batch size is reached
			if(${name(entity)}List.size() == BATCH_SIZE)
			{
				//resolve foreign keys and copy those entities that could not be resolved to the missingRefs list
				${name(entity)}sMissingRefs.addAll(resolveForeignKeys(db, ${name(entity)}List));
				
				<#if entity.getXrefLabels()?exists>
				//update objects in the database using xref_label defined secondary key(s) '${csv(entity.getXrefLabels())}' defined in xref_label
				db.update(${name(entity)}List,dbAction<#list entity.getXrefLabels() as label>, "${label}"</#list>);
				<#else>
				//update objects in the database using primary key(<#list entity.getAllKeys()[0].fields as field><#if field_index != 0>,</#if>${field.name}</#list>)
				db.update(${name(entity)}List,dbAction<#list entity.getAllKeys()[0].fields as field>, "${field.name}"</#list>);
				</#if>
				
				//clear for next batch						
				${name(entity)}List.clear();		
				
				//keep count
				total.set(total.get() + BATCH_SIZE);				
			}
		}
			
		//add remaining elements to the database
		if(!${name(entity)}List.isEmpty())
		{
			//resolve foreign keys, again keeping track of those entities that could not be solved
			${name(entity)}sMissingRefs.addAll(resolveForeignKeys(db, ${name(entity)}List));
			<#if entity.getXrefLabels()?exists>
			//update objects in the database using xref_label defined secondary key(s) '${csv(entity.getXrefLabels())}' defined in xref_label
			db.update(${name(entity)}List,dbAction<#list entity.getXrefLabels() as label>, "${label}"</#list>);
			<#else>
			//update objects in the database using primary key(<#list entity.getAllKeys()[0].fields as field><#if field_index != 0>,</#if>${field.name}</#list>)
			db.update(${name(entity)}List,dbAction<#list entity.getAllKeys()[0].fields as field>, "${field.name}"</#list>);
			</#if>
		}
		
		//second import round, try to resolve FK's for entities again as they might have referred to entities in the imported list
		List<${JavaName(entity)}> ${name(entity)}sStillMissingRefs = resolveForeignKeys(db, ${name(entity)}sMissingRefs);
		
		//if there are still missing references, throw error and rollback
		if(${name(entity)}sStillMissingRefs.size() > 0){
			throw new Exception("Import of '${JavaName(entity)}' objects failed: attempting to resolve in-list references, but there are still ${JavaName(entity)}s referring to ${JavaName(entity)}s that are neither in the database nor in the list of to-be imported ${JavaName(entity)}s. (the first one being: "+${name(entity)}sStillMissingRefs.get(0)+")");
		}
		//else update the entities in the database with the found references and return total
		else
		{				
			<#if entity.getXrefLabels()?exists>
			db.update(${name(entity)}sMissingRefs,DatabaseAction.UPDATE<#list entity.getXrefLabels() as label>, "${label}"</#list>);
			<#else>
			db.update(${name(entity)}sMissingRefs,DatabaseAction.UPDATE<#list entity.getAllKeys()[0].fields as field>, "${field.name}"</#list>);
			</#if>
		
			//output count
			total.set(total.get() + ${name(entity)}List.size());
			logger.info("imported "+total.get()+" ${name(entity)} from CSV"); 
		
			return total.get();
		}
	}	
	
	/**
	 * This method tries to resolve foreign keys (i.e. xref_field) based on the secondary key/key (i.e. xref_labels).
	 *
	 * @param db database
	 * @param ${name(entity)}List 
	 * @return the entities for which foreign keys cannot be resolved
	 */
	private List<${JavaName(entity)}> resolveForeignKeys(Database db, List<${JavaName(entity)}> ${name(entity)}List) throws Exception
	{
		//keep a list of ${entity.name} instances that miss a reference which might be resolvable later
		List<${JavaName(entity)}> ${name(entity)}sMissingRefs = new ArrayList<${JavaName(entity)}>();
	
		<#list allFields(entity) as f><#if (f.type == 'xref' || f.type == 'mref') && f.getXrefLabelNames()[0] != f.xrefFieldName>
		<#if f.xrefLabels?size &gt; 1>
		//resolve <#if f.type="mref">mref<#else>xref</#if> '${name(f)}' from composite key ${name(f.getXrefEntityName())}.[${csv(f.getXrefLabelNames())}] -> ${name(f.getXrefEntityName())}.${name(f.getXrefFieldName())})
		Query<${JavaName(f.getXrefEntityName())}> ${name(f)}Query = db.query(${JavaName(f.getXrefEntityName())}.class);
		for(${JavaName(entity)} o: ${name(entity)}List)
		{
			if(<#list f.xrefLabelNames as label>o.get${JavaName(f)}_${JavaName(label)}() != null<#if label_has_next> || </#if></#list>)
			{
				<#if f.type="mref">
				//mref: get pairs as a list query, assume longest list size
				int listSize = 0;
				<#list f.xrefLabelNames as label>
				if(o.get${JavaName(f)}_${JavaName(label)}() != null) listSize = Math.max(o.get${JavaName(f)}_${JavaName(label)}().size(), listSize);
				</#list>
				for(int i = 0; i < listSize; i++)
				{
					//check if list != null, i < size, otherwise 'null'
					<#list f.xrefLabelNames as label>
					${name(f)}Query.eq("${label}", o.get${JavaName(f)}_${JavaName(label)}() != null && i < o.get${JavaName(f)}_${JavaName(label)}().size() ? o.get${JavaName(f)}_${JavaName(label)}().get(i) : null);
					<#if label_has_next>
					${name(f)}Query.and();</#if>
					</#list>
					${name(f)}Query.or();
				}				
				<#else>
				//xref: 
				<#list f.xrefLabelNames as label>
				${name(f)}Query.eq("${label}", o.get${JavaName(f)}_${JavaName(label)}());
				<#if label_has_next>
				${name(f)}Query.and();</#if>
				</#list>
				${name(f)}Query.or();
				</#if>
				
			}
		}
		List<${JavaName(f.xrefEntity)}> ${name(f)}List = ${name(f)}Query.find();
		for(${JavaName(f.xrefEntity)} xref :  ${name(f)}List)
		{
			String key = "";
			<#list f.xrefLabelNames as label>
			//key.put("${label}", xref.get${JavaName(label)}());
			key += "|" + xref.get${JavaName(label)}();
			</#list>
			${name(f)}Keymap.put(key, xref.get${JavaName(f.getXrefFieldName())}());
		}		
		<#else>
		//resolve xref '${name(f)}' from ${name(f.getXrefEntityName())}.${csv(f.getXrefLabelNames())} -> ${name(f.getXrefEntityName())}.${name(f.getXrefFieldName())}
		for(${JavaName(entity)} o: ${name(entity)}List) <#if f.type == "mref">for(${JavaType(f.xrefLabels[0])} xref_label: o.get${JavaName(f)}_${JavaName(f.getXrefLabelNames()[0])}())</#if>
		{
			if(<#if f.type == "mref">xref_label<#else>o.get${JavaName(f)}_${JavaName(f.getXrefLabelNames()[0])}()</#if> != null) 
				${name(f)}Keymap.put(<#if f.type == "mref">xref_label<#else>o.get${JavaName(f)}_${JavaName(f.getXrefLabelNames()[0])}()</#if>, null);
		}
		
		if(${name(f)}Keymap.size() > 0) 
		{
			List<${JavaName(f.xrefEntity)}> ${name(f)}List = db.query(${JavaName(f.getXrefEntityName())}.class).in("${f.getXrefLabelNames()[0]}",new ArrayList<Object>(${name(f)}Keymap.keySet())).find();
			for(${JavaName(f.xrefEntity)} xref :  ${name(f)}List)
			{
				${name(f)}Keymap.put(xref.get${JavaName(f.getXrefLabelNames()[0])}(), xref.get${JavaName(f.getXrefFieldName())}());
			}
		}
		</#if>
		</#if></#list>
		//update objects with foreign key values
		for(${JavaName(entity)} o:  ${name(entity)}List)
		{
			while(true){
				<#list allFields(entity) as f>
				<#if f.type == 'xref'  && f.getXrefLabelNames()[0] != f.getXrefFieldName()>
				//update xref ${f.name}
				if(<#list f.xrefLabelNames as label><#if label_index &gt; 0> || </#if>o.get${JavaName(f)}_${JavaName(label)}() != null</#list>) 
				{
					<#if f.xrefLabelNames?size &gt; 1>
					String key = "";
					<#list f.xrefLabelNames as label>
					//key.put("${label}", o.get${JavaName(f)}_${JavaName(label)}());
					key += "|" + o.get${JavaName(f)}_${JavaName(label)}();
					</#list>
					<#else>	
					${type(f.xrefLabels[0])} key = o.get${JavaName(f)}_${JavaName(f.xrefLabelNames[0])}();
					</#if>
					if(${name(f)}Keymap.get(key) == null)
					{
					<#if entity.name == f.getXrefEntityName()>
						<#if f.nillable == true>
						${name(entity)}sMissingRefs.add(o);
						break;
						<#else>
						throw new Exception("Import of '${entity.name}' objects failed: attempting to resolve in-list references, but this is (at the moment) not possible for non-nillable XREF fields");
						</#if>
					<#else>
						throw new Exception("Import of '${entity.name}' objects failed: cannot find ${JavaName(f.getXrefEntityName())} for <#list f.xrefLabelNames as label><#if label_index &gt; 0> and </#if>${name(f)}_${label}='"+o.get${JavaName(f)}_${JavaName(label)}()+"'</#list>");
					</#if>
					}
					o.set${JavaName(f)}_${JavaName(f.getXrefField())}(${name(f)}Keymap.get(key));
				}
				<#elseif f.type == 'mref'  && f.getXrefLabelNames()[0] != f.getXrefFieldName()>
				//update mref ${f.name}
				if(<#list f.xrefLabelNames as label><#if label_index &gt; 0> || </#if>o.get${JavaName(f)}_${JavaName(label)}() != null</#list>) 
				{
					List<Integer> mrefs = new ArrayList<Integer>();
					boolean breakToNext${JavaName(entity)} = false;

					int listSize = 0;
					<#list f.xrefLabelNames as label>
					if(o.get${JavaName(f)}_${JavaName(label)}() != null) listSize = Math.max(o.get${JavaName(f)}_${JavaName(label)}().size(), listSize);
					</#list>
					for(int i = 0; i < listSize; i++)
					{
						<#if f.xrefLabelNames?size &gt; 1>
						String key = "";
						<#list f.xrefLabelNames as label>
						key = key + "|" +(o.get${JavaName(f)}_${JavaName(label)}() != null && i < o.get${JavaName(f)}_${JavaName(label)}().size() ? o.get${JavaName(f)}_${JavaName(label)}().get(i) : "null");
						</#list>
						<#else>	
						${JavaType(f.xrefLabels[0])} key = o.get${JavaName(f)}_${JavaName(f.xrefLabelNames[0])}().get(i);
						</#if>
						if(${name(f)}Keymap.get(key) == null){
							<#if entity.name == f.getXrefEntityName()>
								<#if f.nillable == true>
							${name(entity)}sMissingRefs.add(o);
							breakToNext${JavaName(entity)} = true;
							break;
								<#else>
							throw new Exception("Import of '${entity.name}' objects failed: attempting to resolve in-list references, but this is (at the moment) not possible for non-nillable MREF fields");
								</#if>
							<#else>
							logger.error("Import of '${entity.name}' objects failed: "+o);
							throw new Exception("Import of '${entity.name}' objects failed: cannot find <#list f.xrefLabelNames as label><#if label_index &gt; 0> and </#if>${name(f)}_${label}='"+(o.get${JavaName(f)}_${JavaName(label)}() != null && i < o.get${JavaName(f)}_${JavaName(label)}().size() ? o.get${JavaName(f)}_${JavaName(label)}().get(i) : "null")+"'</#list>");
							</#if>
						}
						mrefs.add(${name(f)}Keymap.get(key));
					}
					if(breakToNext${JavaName(entity)}){
						break;
					}
					o.set${JavaName(f)}_${JavaName(f.xrefField)}(mrefs);
				}
				</#if></#list>
				break;
			}
		}
		
		<#list allFields(entity) as f><#if (f.type == 'xref' || f.type == 'mref') && f.getXrefLabelNames()[0] != f.getXrefFieldName()>
		${name(f)}Keymap.clear();
		</#if></#list>
		
		return ${name(entity)}sMissingRefs;
	}
}

